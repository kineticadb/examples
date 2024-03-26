/* Workbook: Real-Time Route Optimization and Alerting */
/* Workbook Description:  */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 4 */


/* Worksheet: Data */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCES
We will be using three different data sources for this example: one Kafka topic and two small files loaded from AWS S3. Our first task is to register all of these data sources so that we can connect to them.
"msdo_data_source" data source will retrieve data for depot and customer information, and "msdo_truck_locations" data source will retrieve data for real-time truck information from the Kafka server.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Credentials for Kafka cluster
DROP TABLE IF EXISTS kafka_credential_object;
CREATE OR REPLACE CREDENTIAL kafka_credential_object
TYPE = 'kafka'
WITH OPTIONS (
    'security.protocol' = 'SASL_SSL',
    'sasl.mechanism' = 'PLAIN',
    'sasl.username'='QZN62QB2RBTLW74L',
    'sasl.password'='iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- The AWS S3 Bucket For Supply and Demand Tables
CREATE OR REPLACE DATA SOURCE msdo_data_source
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);

--Creating Data Source to reach the Kafka Server
CREATE OR REPLACE DATA SOURCE msdo_truck_locations
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'msdo_truck_locations',
    credential = 'kafka_credential_object'
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE & LOAD DATA
In the next step, we will create a new table called 'msdo_trucks' and load it with data retrieved from the Kafka server.
The subscription to the Kafka server will be canceled after 2 hours.
*/
/* TEXT Block End */


/* SQL Block Start */
--Creating a new table for the data from Kafka Server
CREATE OR REPLACE TABLE msdo_trucks (
    "DEMAND_DROP" DOUBLE NOT NULL,
    "DEMAND_ID" INTEGER NOT NULL,
    "REGIONID" INTEGER NOT NULL,
    "START_TIME" BIGINT NOT NULL,
    "STATUS" VARCHAR (128, dict) NOT NULL,
    "SUPPLY_ID" INTEGER NOT NULL,
    "TIMESTAMP" TIMESTAMP NOT NULL,
    "TRACKID" VARCHAR (64, dict) NOT NULL,
    "X" DOUBLE NOT NULL,
    "Y" DOUBLE NOT NULL
);
/* SQL Block End */


/* SQL Block Start */
--Loading the data in Kafka Server into msdo-trucks
LOAD DATA INTO msdo_trucks
FROM FILE PATH ''
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'msdo_truck_locations',
    SUBSCRIBE = TRUE,
    ERROR_HANDLING = 'permissive',
    kafka_offset_reset_policy = 'latest', -- start the ingest from the latest messages
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE A GRAPH REPRESENTATION OF THE DC AREA ROAD NETWORK
The following block of code creates a graph of the road network in an around Washtington DC. To do this, first we need to load spatial data that represents the road network. This spatial data contains WKT lines for different road segments in DC along with the direction of travel and the time it takes to traverse that segment. When we create a graph using this road network data, under the hood Kinetica converts each spatial line representing a road segment into a directed edge with an associated weight. The weight in this case is the time for traversing that segment.
Kinetica uses a native representation for storing graph data. However, we can set an additional option in the create graph query that stores a relational representation of a graph object. In the query we have set that to dc_area_table. We can use this table to visualize this graph on a map as shown below.
For more information on Kinetica's graph API please refer to the following playlist:
https://www.youtube.com/watch?v=wUpeZbzbK4Y&list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD
*/
/* TEXT Block End */


/* SQL Block Start */
--Load data
DROP TABLE IF EXISTS dc_shape;
LOAD DATA INTO dc_shape
FROM FILE PATHS 'dc/dc_roads.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'msdo_data_source'
);

--DC_AREA Graph Creation
CREATE OR REPLACE DIRECTED GRAPH dc_area 
    (EDGES => INPUT_TABLE (
        SELECT  id AS ID,
            wkt AS WKTLINE,
            dir AS DIRECTION,
            time AS WEIGHT_VALUESPECIFIED
        FROM dc_shape),
        OPTIONS => KV_PAIRS
        (
            graph_table = 'dc_area_table',
            add_turns = 'true'
        )
    );
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE SUPPLY AND DEMAND TABLES
The following block of code creates and populates customer and depot tables.
For the customer table the "id" is a unique identifier for each customer, "location" stores geographic information for each customer, "num_of_pkg" represents the number of packages each customer has requested, "vol_of_pkg" indicates the volume of packages each customer expects, "time_penalty" represents the additional time in seconds that a driver may take to deliver packages to this customer, and "region_id" is used to identify the region associated with each customer.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop existing tables 
DROP TABLE IF EXISTS customer;

--Load data
LOAD DATA INTO customer
FROM FILE PATHS 'dc/customers_with_region.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'msdo_data_source'
);

SELECT * FROM customer 
LIMIT 5;
/* SQL Block End */


/* TEXT Block Start */
/*
For the truck table "truck_id" serves as a unique identifier for each truck, "region_id" is used to identify the region where the truck operates, "location" stores geographic information for each truck's current position, "cap_of_pkg" signifies the maximum number of packages that a truck can carry, "cap_of_vol" indicates the maximum volume of packages that a truck can accommodate, and "station_name" specifies the depot which each truck belongs.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS truck;

--Load data
LOAD DATA INTO truck
FROM FILE PATHS 'dc/trucks_with_region.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'msdo_data_source'
);

SELECT * FROM truck 
LIMIT 5;
/* SQL Block End */


/* Worksheet: Find the Optimal Route */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
HOW DOES AN MSDO SOLVER WORK?
An MSDO solver takes the following inputs - a graph network, supply and demand points. It uses these to find the best routes between supply and demand points based on the constraints and costs associated with each of them.
- A demand point can have up to two constraints and a cost factor associated with it. In the current case the two constraints are the total number and volume of packages at each customer location. While the cost factor is the time it takes to unload the packages at a particular customer location.
- A supply vehicle can have up to two constraints associated with it. In our case, each supply truck is constrained on the number and volume of packages it can carry.
SOLVER SPECIFICATION
For the "solve_method" section, we opt for "match_supply_demand," indicating that our solver will find the most optimized route in the MSDO concept. The output of the solver is stored in the "solution_table", which is set to the optimal_route in the following query.
OPTIONAL PARAMETERS
The MSDO solver can also take a set of optional parameters. These include the following.
Left Turn Penalty:
Assigns a time penalty for each left turn made by the trucks.
Right Turn Penalty:
Assigns a time penalty for each right turn made by the trucks.
Intersection Penalty:
Assigns a time penalty for each truck that traverses intersections.
Sharp Turn Penalty:
Assigns a time penalty for each sharp turn made by the trucks.
Max Stops:
Sets a limit on the number of stops a supplier can make in a single round trip.
Partial Loading:
Provides flexibility by allowing suppliers to off-load at the demand side, even if the remaining supply is insufficient to fulfill the demand locations requirements. Or in other words if this is set to false a supplier has to fully satisfy a demand locations requirements and cannot partially meet them.
Unit Unloading Cost:
Sets a cost of each unit load in the total trip cost. It becomes effective when the unit cost per load exceeds zero.
Once the solver is run, an "Animate" button will appear at the end of the block. Note that the "output_tracks" parameter has to be set to "true" for this to work.
*/
/* TEXT Block End */


/* SQL Block Start */
--MSDO Solver
DROP TABLE IF EXISTS optimal_route;
EXECUTE FUNCTION MATCH_GRAPH(
    GRAPH => 'dc_area',
    SAMPLE_POINTS => INPUT_TABLES
    (
        (
            SELECT 
                id AS demand_id,
                location AS demand_wktpoint,
                region_id AS demand_region_id,
                num_of_pkg AS demand_size,
                vol_of_pkg AS demand_size2,
                time_penalty AS demand_penalty
            FROM customer
        ),
        (
            SELECT 
                region_id AS supply_region_id,
                location AS supply_wktpoint,
                truck_id AS supply_id,
                cap_of_pkg AS supply_size,
                cap_of_vol AS supply_size2
            FROM truck
        )
    ),
    SOLVE_METHOD => 'match_supply_demand',
    SOLUTION_TABLE => 'optimal_route',
    OPTIONS => kv_pairs
    (
        output_tracks = 'true',
        svg_width = '1200', svg_height = '900',  
        svg_speed = '80', svg_basemap = 'true',
        left_turn_penalty = '25',
        right_turn_penalty = '15',
        intersection_penalty = '45',
        sharp_turn_penalty = '30',
        max_stops = '5',
        partial_loading = 'false',
        unit_unloading_cost = '60'
    )
);
/* SQL Block End */


/* SQL Block Start */
--Alter an attribute type in "optimal_route" table
ALTER TABLE optimal_route
ALTER COLUMN demand_id varchar(4);

-- Create a persisted version of the optimal route so that it can be used in materialized views.
CREATE OR REPLACE TABLE persisted_route as 
SELECT * from optimal_route;
/* SQL Block End */


/* Worksheet: Real-Time Tracking */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
IN THIS SHEET
In this sheet we will set up a real time alerting system that monitors delivery trucks and compares their current position with the optimal route that was calculated in the previous sheet.
REAL-TIME GPS COORDINATES OF SUPPLY TRUCKS
The map below shows the 'real-time' location of delivery trucks. In the data sheet, we ingest GPS data for each truck into the 'msdo_trucks' table in Kinetica. These GPS coordinates represent simulated routes that we created based on the optimal routes from the solver but with some added random noise that mimics slower or faster drivers.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
OUTPUT OF THE OPTIMAL ROUTE SOLVER
Before we delve into our analysis, it's important to familiarize ourselves with the solver's output. Run the block below to see the output. It consists of eight distinct columns, each serving a specific purpose.
- The "x" and "y" columns provide coordinates for the trucks' positions.
- The "timestamp" columnindicates the time elapsed in seconds(delta) since a truck commenced its route.
- "trackid" is a unique identifier generated from the combination of "region_id" and "supply_id."
- "region_id" identifies the region to which each truck is assigned. In this scenario, there are three distinct regions.
- "supply_id" is a unique identifier assigned to each truck.
- "demand_id" reveals the unique identifier of the next destination for each truck.
- "demand_drop" signifies the quantity of packages (demand_size) that will be delivered at the next destination.
*/
/* TEXT Block End */


/* SQL Block Start */
--Output of the "optimal_route"
SELECT * FROM optimal_route;
/* SQL Block End */


/* TEXT Block Start */
/*
IDENTIFY THE MOST RECENT TRUCK ROUTE FROM KAFKA
As noted earlier, the kafka server is constantly recieving and sending GPS coordinates for the same routes for each truck (with some noise). This means that at any given point the same truck could have data for multiple routes on Kafka (including the current route and the previous ones). So when Kinetica ingests the data, it might contain duplicate data from multiple routes. To address this issue, when we simulate a route, we add a route start time to each of message sent to Kafka, which records the time that a truck set off from a supply depot. We can select the most recent route in the data using this start time value.
The following query creates a materialized view that identifies the most recent routes using the start time value. Notice that it is set to 'REFRESH EVERY 5 MINUTES', this means that every 5 minutes this query is updated with the most recent real time values from Kafka. If a new start time is detected then the query below will immediately recognize it.
*/
/* TEXT Block End */


/* SQL Block Start */
-- When did each route start in Kafka Server?
CREATE OR REPLACE MATERIALIZED VIEW start_times 
REFRESH EVERY 5 MINUTES AS
SELECT TRACKID, MAX(start_time) AS start_time
FROM msdo_trucks
GROUP BY trackid;

SELECT TRACKID, DATETIME(start_time) AS start_time FROM start_times;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE OPTIMAL ROUTES
The output from the MSDO solver does not have a 'start_time'. It only records the time in seconds that it takes for a supplier to move from one point to another. To compare the optimal route to the current real time route, we will need to add the start times for each 'real' route to the optimal route. In the following query, we use the identifier for each supply truck (TRACKID) to join the 'start_times' table we created in the previous query with the optimal route. We then combine the start times of each route with the time values from the solver to create the optimal TIMESTAMP values for each route.
NOTE
: Make sure that you have run the ALTER TABLE query in the block below the MSDO solver query on the previous worksheet before running this query.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create a new solver table with relative timestamps based on each trucks start time
CREATE OR REPLACE MATERIALIZED VIEW solver_route
REFRESH ON CHANGE AS
SELECT 
    s.trackid,
    s.x,
    s.y,
    s.region_id, 
    s.supply_id, 
    INT(s.demand_id) AS demand_id,
    TIMESTAMP(LONG(ROUND(s.TIMESTAMP * 1000) + start_time)) AS TIMESTAMP
FROM persisted_route AS s
JOIN start_times AS st
ON s.trackid = st.trackid;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM solver_route;
/* SQL Block End */


/* TEXT Block Start */
/*
RECORD ALL THE STOPS FOR A SUPPLIER
A supplier truck can have two types of stops - either a customer location or a supply depot. The query below creates a next_stop table that combines both these types of stops. We will use this table to identify whether a truck is on schedule towards its next stop when compared to the optimal route.
*/
/* TEXT Block End */


/* SQL Block Start */
--Combining Customer and Truck Tables
CREATE OR REPLACE TABLE next_stop AS
(SELECT DISTINCT CONCAT(region_id, truck_id) AS destination_id, 'depot' AS destination_label, location as location FROM truck)
UNION
(SELECT DISTINCT ID AS destination_id,'customer' AS destination_label, location as location  FROM customer);
/* SQL Block End */


/* TEXT Block Start */
/*
CALCULATE THE DISTANCE TO NEXT STOP FOR OPTIMAL ROUTES
Earlier we had created the optimal routes based on the start times of the current supply routes from Kafka. The query below calculates the distance to the next stop on a route from each optimal truck location using the STXY_DISTANCE function. Our alerting system will compare these distances with those for the actual routes.
*/
/* TEXT Block End */


/* SQL Block Start */
--CALCULATE DISTANCES TO NEXT DESTINATION AT EACH POINT ON THE OPTIMAL ROUTE
CREATE OR REPLACE MATERIALIZED VIEW solver_distances
REFRESH ON CHANGE AS
SELECT
/*KI_HINT_PROJECT_MATERIALIZED_VIEW */
    s.TIMESTAMP, 
    s.TRACKID,
    s.X,
    s.Y,
    d.destination_id,
    d.destination_label AS solver_destination,
    STXY_DISTANCE(s.x, s.y, d.location, 1) AS dist_to_next_stop
FROM
(
    SELECT 
        *,
        IF(demand_id > 30, CONCAT(region_id, supply_id), demand_id) AS destination_id -- If demand id is greater than 30 it means that the truck is going back to the depot
    FROM solver_route
)  AS s
JOIN next_stop AS d
ON s.destination_id = d.destination_id;
/* SQL Block End */


/* TEXT Block Start */
/*
DISTANCE TO NEXT STOP FOR ACTUAL TRUCK ROUTES
Now we repeat the same query but this time for the actual routes from Kafka.
*/
/* TEXT Block End */


/* SQL Block Start */
--CALCULATE THE ACTUAL DISTANCES TO NEXT DESTINATION FOR THE REAL TIME ROUTES
CREATE OR REPLACE MATERIALIZED VIEW actual_distances
REFRESH EVERY 5 SECONDS AS
SELECT
    k.TIMESTAMP, 
    k.TRACKID,
    k.X,
    k.Y,
    k.status,
    d.destination_id,
    d.destination_label AS actual_destination,
    STXY_DISTANCE(k.X, k.Y, d.location, 1) AS dist_to_next_stop
FROM
(
    SELECT 
        *, 
        IF(demand_id > 30, CONCAT(regionid, supply_id), demand_id) AS destination_id
    FROM msdo_trucks
) AS k 
JOIN next_stop AS d
ON k.destination_id = d.destination_id;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM
(
    SELECT 
        DATETIME(timestamp) AS TIMESTAMP,
        dist_to_next_stop,
        'ACTUAL' AS TYPE,
        destination_id
    FROM actual_distances 
    WHERE TRACKID = '1001_101'
)
UNION
(
    SELECT 
        DATETIME(timestamp) AS TIMESTAMP,
        dist_to_next_stop,
        'SOLVER' AS TYPE,
        destination_id
    FROM solver_distances 
    WHERE TRACKID = '1001_101' AND TIMESTAMP BETWEEN (SELECT MIN(timestamp) FROM actual_distances) AND (SELECT MAX(timestamp) FROM actual_distances)
)
ORDER BY TIMESTAMP;
/* SQL Block End */


/* TEXT Block Start */
/*
COMPARING TRUCK LOCATIONS
In addition to comparing distances to the next stop for each truck, we are also analyzing the real-time locations of the trucks. We can compare the solver's predefined route, which adheres to the expected schedule, with the actual trucks that may be operating on a delayed route. This comparison allows us to assess whether the actual trucks are moving at a faster pace than the optimal route or to observe any delays in their progress.
In the code block below, we filter and retain only the data from the Kafka server for the past 10 minutes. This data is then used to compare the real-time GPS signals of the trucks with their expected locations based on the results from the optimal route table. It's important to note that since we are only keeping the last 10 minutes, some trucks may not appear on the map below. This occurs because certain trucks have longer routes than others, and the Kafka server resets itself to simulate new routes when the longest route is completed.
The green truck signals indicate real-time GPS locations, while the blue truck signals represent the positions of solver trucks.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW route_compare
REFRESH EVERY 5 SECOND AS
SELECT *,
    act.dist_to_next_stop - s.dist_to_next_stop AS distance_gap,
    IF(act.dist_to_next_stop > s.dist_to_next_stop, 'Lagging', 'Leading') AS speed_indicator
FROM 
(
    SELECT * FROM 
    actual_distances 
    WHERE TIMESTAMP > NOW() - INTERVAL '10' MINUTE -- only keep the last 10 minutes of data
) AS act
INNER JOIN solver_distances s 
ON act.TRACKID = s.TRACKID AND ASOF(act.TIMESTAMP, s.TIMESTAMP, INTERVAL '-10' SECOND, INTERVAL '1' MINUTE, MIN) AND act.destination_id = s.destination_id;
/* SQL Block End */


/* TEXT Block Start */
/*
🚨 Alerts
Alerts can be generated under various circumstances, including when a truck is approaching its next location.
In this particular scenario, we will trigger alerts when the time gap between the actual truck position and the optimal route prediction exceeds 2000 seconds.
These alerts can easily be directed to various tools, such as Slack, for effective monitoring and notification.
While, for the purposes of this demo, the alerts are not currently routed to any specific tools, they can be accessed through the destination link provided below.
❗️
Note:
The link might be expired, and if so, there will be an error message saying '404 Token not found.' Please click the 'Back to Webhook.site' button, and you will be able to see the alerts on the page. Also, you can update the destination link by copying and pasting the URL on the website.
*/
/* TEXT Block End */


/* SQL Block Start */
--An example query for alert creation
CREATE STREAM alert_trucks 
ON TABLE route_compare
WHERE distance_gap > 2000
WITH OPTIONS 
(
    DESTINATION = 'https://webhook.site/5ce5b088-b02d-448c-983a-8d7380b27311'
);
/* SQL Block End */

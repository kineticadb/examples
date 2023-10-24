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
CREATE THE MAP
The following block of code creates a graph of the road network in an around Washtington DC. To do this, first we need to load spatial data that represents the road network. This spatial data contains WKT lines for different road segments in DC along with the direction of travel and the time it takes to traverse that segment. When we create a graph using this road network data, under the hood Kinetica converts each spatial line representing a road segment into a directed edge with an associated weight. The weight in this case is the time for traversing that segment.
Kinetica uses a native representation for storing graph data. However, we can set an additional option in the create graph query that stores a relational representation of a graph object. In the query we have set that to dc_area_table. We can use this table to visualize this graph on a map as shown below.
For more information on Kinetica's graph API please refer to the playlist:
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
        FROM ki_home.dc_shape),
        OPTIONS => KV_PAIRS(
            'graph_table' = 'ki_home.dc_area_table',
            'add_turns' = 'true'
        )
    );
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE SUPPLY AND DEMAND TABLES
The following block of code creates and populates customer and depot tables.
For the customer table the "id" is a unique identifier for each customer, "location" stores geographic information for each customer, "num_of_pkg" represents the number of packages each customer has requested, "vol_of_pkg" indicates the volume of packages each customer expects, "time_penalty" represents the additional time in seconds that a driver may take to deliver packages to this customer, and "region_id" is used to identify the region associated with each customer.
For the truck table "truck_id" serves as a unique identifier for each truck, "region_id" is used to identify the region where the truck operates, "location" stores geographic information for each truck's current position, "cap_of_pkg" signifies the maximum number of packages that a truck can carry, "cap_of_vol" indicates the maximum volume of packages that a truck can accommodate, and "station_name" specifies the depot which each truck belongs.
*/
/* TEXT Block End */


/* SQL Block Start */
--Creating Customer(Demand) Table:
CREATE OR REPLACE TABLE customer(
    ID int,
    location wkt not null,   
    NumOfPkg int not null,
    VolOfPkg float not null,
    TimePenalty float,
    RegionID int
);

--Creating Truck(Supply) Table:
CREATE OR REPLACE TABLE truck(
    TruckID int,
    RegionID int,
    location wkt not null,
    CapOfPkg int not null,
    CapOfVol float not null,
    StationName String(32)
);
/* SQL Block End */


/* SQL Block Start */
--Load data
LOAD DATA INTO customer
FROM FILE PATHS 'dc/customers_with_regions.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'msdo_data_source'
);

--Load data
LOAD DATA INTO truck
FROM FILE PATHS 'dc/trucks_with_regions.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'msdo_data_source'
);
/* SQL Block End */


/* Worksheet: Find the Optimal Route */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
HOW MSDO SOLVER WORKS?
To successfully run the MSDO solver, we begin by selecting a specific graph, in this case, the "dc_area" graph from the previous sheet. Within this optimization process, we specify two crucial data sources: the supply and demand tables, which in this instance are the "truck" and "customer" tables. Both tables must contain specific attributes such as id, region id, location, and size attribute(s). The "demand_penalty" attribute is optional for the demand side.
For the "solve_method" section, we opt for "match_supply_demand," indicating that our solver will find the most optimized route in the MSDO concept. The "solution_table" is defined as the new table created and populated by the solver.
Finally, in the last part, we define our options, enabling us to filter variables or establish rules. Kinetica provides a variety of additional options that can be seamlessly integrated with the MSDO solver. For more options:
https://docs.kinetica.com/7.1/feature_overview/match_graph_feature_overview/
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
Provides flexibility by allowing suppliers to off-load at the demand side, even if the remaining supply is insufficient to fulfill the store's requirements.
Unit Unloading Cost:
Sets a cost of each unit load in the total trip cost. It becomes effective when the unit cost per load exceeds zero.
Once the solver is run, an "Animate" button will appear at the end of the block. This feature is provided using SVG. To enable this option, set the "output_trucks" parameter to "true."
*/
/* TEXT Block End */


/* SQL Block Start */
--MSDO Solver
DROP TABLE IF EXISTS optimal_route;
execute function match_graph(
    graph => 'dc_area',
    sample_points => input_tables
    (
        (
            SELECT 
                id AS demand_id,
                location AS demand_wktpoint,
                regionid AS demand_region_id,
                numOfPkg AS demand_size,
                volOfPkg AS demand_size2,
                timepenalty AS demand_penalty
            FROM ki_home.customer
        ),
        (
            SELECT 
                regionid AS supply_region_id,
                location AS supply_wktpoint,
                truckid AS supply_id,
                capOfPkg AS supply_size,
                capOfVol AS supply_size2
            FROM ki_home.truck
        )
    ),
    solve_method => 'match_supply_demand',
    solution_table => 'optimal_route',
    options => kv_pairs
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
/* SQL Block End */


/* Worksheet: Real-Time Tracking */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
REAL-TIME GPS COORDINATES OF SUPPLY TRUCKS
Within the data sheet, we have established an ingestion pipeline for a Kafka stream, which delivers real-time GPS coordinates for supply trucks. The map displayed below illustrates the current positions of each truck in real-time. These trucks are adhering to the same route as the optimal path presented. These trucks are following the same route as the optimal path depicted, but each one experiences random delays to simulate a more realistic environment. Consequently, the real-time GPS coordinates may have more delays compared to the trucks following the optimal route.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
OUTPUT OF THE OPTIMAL ROUTE SOLVER
Before we delve into our analysis, it's important to familiarize ourselves with the solver's output. The output consists of eight distinct columns, each serving a specific purpose.
- The "x" and "y" columns provide coordinates for the trucks' positions.
- The "timestamp" columnindicates the time elapsed in seconds(delta) since a truck commenced its route.
- "trackid" is a unique identifier generated from the combination of "region_id" and "supply_id."
- "region_id" identifies the region to which each truck is assigned. In this scenario, there are three distinct regions.
- "supply_id" is a unique identifier assigned to each truck.
- "demand_id" reveals the unique identifier of the next destination for each truck.
- "demand_drop" signifies the quantity of packages (demand_size) that will be delivered at the next destination.
With this understanding in place, let's proceed to examine the solver's output in more detail by executing the query below.
*/
/* TEXT Block End */


/* SQL Block Start */
--Output of the "optimal_route"
SELECT * FROM optimal_route;
/* SQL Block End */


/* TEXT Block Start */
/*
FORMAT KAFKA SERVER DATA
We can compare the data generated by the MSDO solver with the data obtained from the Kafka server. However, it's important to note that the Kafka server operates continuously, causing the trucks' routes to reset once they complete. Consequently, the Kafka server may produce duplicate coordinate signals with varying timestamp values, which can adversely impact our analysis. To mitigate the issue of duplicate records, we can opt to select records that share the same start time. Each time the trucks commence their routes, their routes are marked with their respective starting timestamps, so we identify and select the records belongs the same route.
The following query will establish a materialized view designed to retain information corresponding to truck routes from the Kafka server, specifically focusing on entries that share a same starting time.
*/
/* TEXT Block End */


/* SQL Block Start */
-- When did each route start in Kafka Server?
CREATE OR REPLACE MATERIALIZED VIEW start_times 
REFRESH EVERY 5 MINUTE AS
SELECT TRACKID, MAX(start_time) AS start_time
FROM msdo_trucks
GROUP BY trackid;
/* SQL Block End */


/* TEXT Block Start */
/*
CONVERTING DELTA VALUES
In the following code block, we are creating a materialized view that modifies the data in the 'optimal_route' table. Specifically, we are converting the delta values in the 'optimal_route' table from seconds to milliseconds. Once these conversions are made, we aim to incorporate the 'start_times' values into each delta, allowing for meaningful comparisons between the deltas of actual trucks and solver trucks.
To achieve this, we utilize an inner join between the 'optimal_route' table and the 'start_times' table, ensuring that each route's 'start_time' value corresponds appropriately with the data in the 'optimal_route' table.
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
FROM optimal_route AS s
JOIN start_times AS st
ON s.trackid = st.trackid;
/* SQL Block End */


/* TEXT Block Start */
/*
COMBINING SUPPLY AND DEMAND TABLES
In the upcoming section, we will merge the customer and truck tables. The primary objective behind this merging process is to consolidate all relevant information into a single table. By doing so, we ensure that, for each truck destination, we have comprehensive access to detailed information about both customers and trucks within a unified dataset. We will utilize the newly created "next_stop" table in subsequent analyses, enabling us to construct join statements that provide more in-depth insights into truck logistics.
*/
/* TEXT Block End */


/* SQL Block Start */
--Combining Customer and Truck Tables
CREATE OR REPLACE TABLE destinations AS --next_stop
(SELECT DISTINCT CONCAT(REGIONID, TruckID) AS destination_id, 'depot' AS destination_label, location as location FROM ki_home.truck)
UNION
(SELECT DISTINCT ID AS destination_id,'customer' AS destination_label, location as location  FROM ki_home.customer);
/* SQL Block End */


/* TEXT Block Start */
/*
FURTHER ANALYSIS
In our further analysis, we have the capability to compare the solver's route with real-time truck signals. The solver's route serves as a representation of the expected schedule for the trucks, enabling us to contrast it with the real-time truck signals received from the Kafka server. One valuable aspect of this analysis involves calculating the distance to the next destination for GPS points along a route. This calculation allows us to make comparisons between a truck's current speed and that of the optimal route, thereby determining whether the truck is moving faster or slower than expected.
The following query will create a new materialized view to display the distance to the next destination stop for the solver's route using the "solver_route" table. Following the creation of this new materialized view, we will proceed to display the distances to the next stop for truck 305.
*/
/* TEXT Block End */


/* SQL Block Start */
--CALCULATE DISTANCES TO NEXT DESTINATION AT EACH POINT ON THE OPTIMAL ROUTE
CREATE OR REPLACE MATERIALIZED VIEW solver_distances
REFRESH ON CHANGE AS
SELECT
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
        IF(demand_id > 30, CONCAT(region_id, supply_id), demand_id) AS destination_id
    FROM solver_route
)  AS s
JOIN destinations AS d
ON s.destination_id = d.destination_id;

--Distance to next destination for solver trucks
SELECT DATETIME(timestamp) AS timestamp, dist_to_next_stop FROM solver_distances 
WHERE trackid = '1003_305';
/* SQL Block End */


/* TEXT Block Start */
/*
The following query will display the distance to the next destination stop for the real-time truck signaks using the "msdo_trucks" table. Following the creation of this new materialized view, we will proceed to display the distances to the next stop for truck 305.
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
JOIN destinations AS d
ON k.destination_id = d.destination_id;

--Distance to next destination for actual trucks
SELECT DATETIME(timestamp) AS timestamp, dist_to_next_stop FROM actual_distances 
WHERE trackid = '1003_305';
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
    DESTINATION = 'https://webhook.site/17ee7a7e-c7fd-4c29-87fc-7a0b58091c8f'
);
/* SQL Block End */

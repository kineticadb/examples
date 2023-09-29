/* Workbook: MSDO Real-Time Tracking */
/* Workbook Description:  */


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
Create & Load Data
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
    -- shard_key(TRACKID)
);

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
The following block of code creates a graph for the DC Area. To create this graph, we need to load spatial data and convert it into a map. Each single line in the spatial data becomes a directed edge, and each edge is associated with a time and weight value. For more information, please refer to Kinetica's tutorial video on Geospatial Data:
https://www.youtube.com/watch?v=Kq0bCdlWmUA&list=PLtLChx8K0ZZWxcmK4tD058UWWh0HJX2hQ&index=3
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
The block of code below creates and populates customer and depot tables.
*/
/* TEXT Block End */


/* SQL Block Start */
--Creating Customer(Demand) Table:
CREATE OR REPLACE TABLE customer(
    ID INT,
    location WKT NOT NULL,
    NumOfPkg INT NOT NULL,
    VolOfPkg FLOAT NOT NULL,
    TimePenalty FLOAT,
    RegionID INT
);

--Creating Truck(Supply) Table:
CREATE OR REPLACE TABLE truck(
    TruckID INT,
    RegionID INT,
    location WKT NOT NULL,
    CapOfPkg INT NOT NULL,
    CapOfVol FLOAT NOT NULL,
    StationName STRING(32)
);

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


/* Worksheet: Primer */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
What is Match Supply Demand Optimization?
Developing a Multiple Supply-Demand Chain Optimization (MSDO) graph solver is crucial for companies like Amazon and Uber. It helps optimize routing based on varying supply and demand quantities within specific industries, such as transporting power, gasoline, or goods.
The goal is to find the most cost-effective routing and scheduling for each vehicle, considering factors like distance, time, and delivery priorities, all while adhering to network constraints defined on a network graph. This approach provides a versatile solution adaptable to the needs of different industries.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
What is Match Supply Demand Optimization?
Matching supply chain logistics to demand-based routing is a complex but crucial daily task for companies like Amazon and Uber. The main goal is to efficiently plan routes for delivery or transportation while considering various industry-specific constraints. To tackle this challenge, Kinetica developed a versatile solution called the Multiple Supply Demand Chain Optimization (MSDO) graph solver. It can optimize the transportation of items like power, fuel, or goods, where both the supply and demand quantities are variable.
For example, it helps determine the best routes for trucks with varying capacities to deliver goods to different locations across a large area. Ultimately, the aim is to minimize transportation costs, whether in terms of distance traveled or delivery time, while adhering to various network constraints.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
MSDO Solver
The block below will find the most efficient route to satisfy the demand of customers using current supply of power. There are some options defined inside of the solver. These options allow us to filter some variables or set some rules. Kinetica offers a range of additional options that can be effectively integrated with the MSDO solver. For more options:
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
Once the solver is run, an "Animate" button will appear at the end of the block. This feature is provided using SVG. To enable this option, set the "output_trucks" parameter to "True."
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
                ID AS DEMAND_ID,
                location AS DEMAND_WKTPOINT,
                regionID AS DEMAND_REGION_ID,
                numOfPkg AS DEMAND_SIZE,
                volOfPkg AS DEMAND_SIZE2,
                timePenalty AS DEMAND_PENALTY
            FROM ki_home.customer
        ),
        (
            SELECT 
                regionID AS SUPPLY_REGION_ID,
                location AS SUPPLY_WKTPOINT,
                truckID AS SUPPLY_ID,
                capOfPkg AS SUPPLY_SIZE,
                capOfVol AS SUPPLY_SIZE2
            FROM ki_home.truck
        )
    ),
    SOLVE_METHOD => 'match_supply_demand',
    SOLUTION_TABLE => 'optimal_route',
    OPTIONS => KV_PAIRS
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
--Alter an attribute type in optimal route table
ALTER TABLE optimal_route
ALTER COLUMN DEMAND_ID varchar(4);
/* SQL Block End */


/* Worksheet: Real-Time Tracking */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
Real-Time Tracking
As incoming data streams into the workbench, the real-time positions of GPS signals emanating from ten distinct trucks are visually represented on the map as black diamond markers.
*/
/* TEXT Block End */


/* SQL Block Start */
--CREATE THE OPTIMAL ROUTE USING START TIMES FOR EACH ROUTE AND MSDO SOLVER TIMESTAMPS
-- When did each route start in Kafka Server?
CREATE OR REPLACE MATERIALIZED VIEW start_times 
REFRESH EVERY 5 MINUTE AS
SELECT TRACKID, MAX(start_time) AS start_time
FROM msdo_trucks
GROUP BY trackid;

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
    --CAST(s.demand_id AS INT) AS demand_id,
    TIMESTAMP(LONG(ROUND(s.timestamp * 1000) + start_time)) AS timestamp
FROM optimal_route AS s
JOIN start_times AS st
ON s.trackid = st.trackid;
/* SQL Block End */


/* TEXT Block Start */
/*
FURTHER ANALYSIS
In addition to real-time tracking, we can perform further analysis. To conduct more in-depth analysis, we need to combine the 'customer' and 'truck' tables.
*/
/* TEXT Block End */


/* SQL Block Start */
--Combining Customer and Truck Tables
CREATE OR REPLACE TABLE destinations AS
(SELECT DISTINCT CONCAT(REGIONID, TruckID) AS destination_id, 'Depot' AS destination_label, location as location FROM ki_home.truck)
UNION
(SELECT DISTINCT ID AS destination_id,'Customer' AS destination_label, location as location  FROM ki_home.customer);
/* SQL Block End */


/* TEXT Block Start */
/*
ADD DISTANCE TO NEXT DESTINATION
We can compute the distance to the next destination for GPS points on a route. This allows us to compare a truck's speed to that of the optimal route, determining whether it is moving faster or slower.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CALCULATE THE ACTUAL DISTANCES TO NEXT DESTINATION FOR THE REAL TIME ROUTES
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

-- CALCULATE DISTANCES TO NEXT DESTINATION AT EACH POINT ON THE OPTIMAL ROUTE
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
        IF(demand_id > 30, CONCAT(region_id, supply_id), demand_id) AS destination_id
    FROM solver_route
)  AS s
JOIN destinations AS d
ON s.destination_id = d.destination_id;
/* SQL Block End */


/* SQL Block Start */
--Distance to next destination for actual trucks
SELECT DATETIME(timestamp) AS timestamp, dist_to_next_stop FROM actual_distances 
WHERE trackid = '1003_305';
/* SQL Block End */


/* SQL Block Start */
--Distance to next destination for solver trucks
SELECT DATETIME(timestamp) AS timestamp, dist_to_next_stop FROM solver_distances 
WHERE trackid = '1003_305';
/* SQL Block End */


/* TEXT Block Start */
/*
COMPARE THE ROUTES
Solver's route, which follows the expected schedule, can be compared with the actual trucks that follow a more delayed schedule.
We can determine if the actual trucks are moving faster than the optimal route or observe their delay.
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
Finally, alerts can be created once a truck is about to arrive at its next locations or for different circumstances. The alerts can be directed to Slack or other tools.
For this demo, the alerts are not directed to any tools, but they can be seen at the destination link below.
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

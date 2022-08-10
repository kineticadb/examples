/* Workbook: Optimal Charging Station */
/* Workbook Description: You are in an electric car that is almost out of charge. 

In this demo, we use Kinetica’s graph API to create a 1.2 million node graph representation of the road network in and around Detroit. We then use this graph network to find the optimal route between a source and destination point by picking the best charging station out of 268 different options. We repeat these computations every 5 seconds using a SQL procedure with new sets of source and destination points that are streaming in from a Kafka topic. */


/* Worksheet: About this demo */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
FIND THE BEST ROUTE WITH A CHARGING PIT STOP
This workbook models the following scenario. You would like to go from a random source point to a random destination point in the Detroit region using an electric car.
However, you have a problem. Your car only has enough charge to travel an hour. To be on the safer side, you would like to find a charging station that is within 40 minutes from when you start before you get to your destination (irrespective of whether the destination is less than an hour away). Once charged, you would like to then proceed to your final destination.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
THE SOLUTION
We will use Kinetica's graph API to solve this problem. Kinetica provides a generic and extensible design of networks with the aim of being tailored or used for various real-life applications, such as transportation, utility, social, and geospatial. Here are the analytical steps.
1. Create the graph: Each road segment (edge) has an associated direction of travel (one-way, two-way), the time taken to travel (weight). We use this information to model the road network as a weighted directed graph.
2. Find the shortest path from the source to all electric vehicle (EV) charging stations that are within range (40 mins).
3. Find the inverse shortest path from all EV charging stations to the destination point.
4. Find the path from the source to destination via a charging station that has minimum cost.
USING KINETICA TO SOLVE HARDER PROBLEMS
We extend this use case further by adding a streaming component. Instead of running the shortest path solvers once, we use a streaming ingest from Kafka that sends out new source and destination points to run this calculation against new inputs every 5 seconds. Since Kinetica is a fully vectorized database, it can perform computationally challenging tasks even on lower end machines.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
THE DATA
1. The road network data for Detroit.
2. Location of EV charging stations
3. A data stream of source and destination points
*/
/* TEXT Block End */


/* Worksheet: Data setup (DDL) */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
CREATE THE SCHEMA
Tables in Kinetica can be organized in unique namespaces called Schemas. This is generally a good practice to keep your data organized and prevent accidental overwrites.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE SCHEMA IF NOT EXISTS ev_route_optimization;
/* SQL Block End */


/* TEXT Block Start */
/*
REGISTER THE STATIC DATA SOURCE
The static data for this example is stored in a Amazon S3 bucket. Let's register that so that we can connect to it. The files in this data source are publicly accessible, so we don't have to use any credentials to access them.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE ev_route_optimization.ev_data_source
LOCATION = 'S3' 
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'guidesdatapublic',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* TEXT Block Start */
/*
REGISTER THE STREAMING DATA SOURCE
The source and destination points are streaming in from a Kafka topic on Confluent. We can first define the credentials for confluent as shown below. Once registered, we can use the credential to connect to the data source on Confluent.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop the table into which we will be streaming (if it exists)
DROP TABLE IF EXISTS ev_route_optimization.source_dest;

CREATE OR REPLACE CREDENTIAL ev_route_optimization.confluent_cred
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'FKHU5OKQSM6J3FZY',
   'sasl.password' = 'BT0b0049Q016ncuMUD0Pt5bRPr6YZu9YNioEtGqfuaN1pPmwyPUVMytUWloqtt8o'
   );
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE ev_route_optimization.streaming_source_dest
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'ev_source_dest',
    credential = 'ev_route_optimization.confluent_cred'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA FROM THE S3 DATA SOURCE INTO TABLES IN KINETICA
We will be loading data from two files that are on AWS S3.
1. The first table contains the road network data for the greater Michigan area. This is a large file that contains WKT linestrings for different road segments along with information on average speeds, time for traversal, direction etc.
2. The second table contains EV charging station locations in the greater Michigan area

✎ NOTE
: We are directly loading the files into tables without defining them in advance. Kinetica has an excellent type inferencing system that does a good job of inferring data types on the fly. In addition, the data that we are using for this example has a Kinetica compatible CSV header format that is used to define the table data.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop the table if it already exists
DROP TABLE IF EXISTS ev_route_optimization.mm_lakes_shape;

LOAD DATA INTO ev_route_optimization.mm_lakes_shape
FROM FILE PATHS 'mm_lakes_shape.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'ev_route_optimization.ev_data_source'
);
/* SQL Block End */


/* SQL Block Start */
-- Drop the table if it already exists
DROP TABLE IF EXISTS ev_route_optimization.mm_evcharging;

LOAD DATA INTO ev_route_optimization.mm_evcharging
FROM FILE PATHS 'mm_evcharging.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'ev_route_optimization.ev_data_source'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA STREAM FROM KAFKA
This time we define the table befor proceeding with the ingest.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the table for streaming ingest
CREATE OR REPLACE TABLE ev_route_optimization.source_dest
(
    source_pt GEOMETRY NOT NULL,
    dest_pt GEOMETRY NOT NULL,
    TIMESTAMP timestamp NOT NULL
);

LOAD DATA INTO ev_route_optimization.source_dest
FROM FILE PATHS ''  /* not mandatory */
FORMAT JSON 
WITH OPTIONS (
    data source = 'ev_route_optimization.streaming_source_dest',
    kafka_group_id = 'BH_90210', /* not mandatory*/
    subscribe = TRUE,
    type_inference_mode = 'speed'
);
/* SQL Block End */


/* Worksheet: Create and explore the graph network */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
CREATE THE GRAPH
Now that we have all the data we need for this example in tables in Kinetica we can start with the analytical tasks.
Our first task is to convert the road network into a graph representation. Each road segment in the data becomes an edge on the graph, the direction of traffic becomes the edge direction and the time for traveling a segment, the edge weight.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH ev_route_optimization.mm_lakes 
(
    EDGES => INPUT_TABLE(
        SELECT  
            shape AS WKTLINE, 
            direction AS DIRECTION,
            time AS WEIGHT_VALUESPECIFIED
        FROM ev_route_optimization.mm_lakes_shape
    ),
    OPTIONS => KV_PAIRS(
        graph_table = 'ev_route_optimization.mm_lakes_graph_table'
    )
);
/* SQL Block End */


/* TEXT Block Start */
/*
A DESCRIPTION OF THE GRAPH NETWORK DATA USING THE OPTIONAL OUTPUT TABLE
When creating the graph we used on an optional parameter to create an output table as well. While this optional tabular representation is not used for any of the analytical tasks using graphs like querying, solving and matching, we can use it to visualize the graph network and to inspect the data.
The table is shown below. Each row in the table represents an edge on the graph and has information on the WKTLINE, the weight (time for traversing the edge) and the direction of travel.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT * FROM ev_route_optimization.mm_lakes_graph_table
LIMIT 5;
/* SQL Block End */


/* TEXT Block Start */
/*
VISUALIZE THE GRAPH
We can use the optional graph output table to visualize the graph on a map. Click on one of the road segments to see the associate row of data from the output table.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
LOCATION OF EV CHARGING STATIONS
We will use the spatial graph network depicted above in combination with the location of the EV charging stations show below to find the optimal path from source and destination points.
*/
/* TEXT Block End */


/* Worksheet: Find the best route */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
RUN THE SHORTEST PATH SOLVERS
Now that we have the graph representation of the road network we can run solvers against it. We want to do this so that the calculation is performed periodically for new data.
1. Our first task is to find all charging stations within 2400 seconds of our starting point.
2. Next we need to find the shortest path from the current destination to all the EV charging stations (inverse shortest path)
3. Finally, we combine all the paths from the first two solves to find the one that has the minimum weight (i.e time for travel). This will be the shortest path from the source to destination with a stop at a charging station.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the optimal route table to store the most current result from the SQL procedure below
CREATE OR REPLACE TABLE ev_route_optimization.optimal_route
(
    pk_id INT (PRIMARY_KEY) NOT NULL,
    wkt1 GEOMETRY NOT NULL,
    wkt2 GEOMETRY NOT NULL,
    wkt_full GEOMETRY
);
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM ev_route_optimization.source_dest
LIMIT 5;
/* SQL Block End */


/* TEXT Block Start */
/*
EXPLAINING THE SQL PROCEDURE AND SOLVERS
The SQL procedure below does all of the analytical work for this example. A SQL procedure is an executable batch of SQL statements that can be run either on schedule or on demand by the user.
The procedure below performs three steps.
1. Calculate the shortest path from the current source to all EV charging stations that are within 40 minutes (sometime this will yield no results because there aren't any charging stations within that radius from the current source point).
2. Calculate the inverse shortest path from all EV charging stations to the current destination.
3. Find the path from the source to a destination with an EV charging station stop that has the lowest combined weight.
The SQL procedure is run on a schedule of every 5 seconds. This means that every 5 seconds we find the most current source and destination point (from the Kafka topic ingest) and recompute the steps above based on these.
The maps below the procedure show the two shortest path routes (Source to EV and EV to destination) and the combined route with minimum cost. They are set to refresh every few seconds so that we see the most updated version of the output.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE PROCEDURE ev_route_optimization.shortest_path_updater
BEGIN
    -- STEP 1: Run the shortest path solver from the source to all EV charging stations within a 2400 sec radius
    CREATE OR REPLACE TABLE ev_route_optimization.source_to_charging_path AS
    SELECT * 
    FROM TABLE (
        SOLVE_GRAPH
        (
            GRAPH => 'ev_route_optimization.mm_lakes',
            SOLVER_TYPE => 'SHORTEST_PATH',
            SOURCE_NODES => INPUT_TABLE(
                SELECT ST_GEOMFROMTEXT(source_pt) AS WKTPOINT 
                FROM ev_route_optimization.source_dest 
                ORDER BY TIMESTAMP DESC -- Find the latest source record
                LIMIT 1
            ),
            DESTINATION_NODES => INPUT_TABLE(
                SELECT 
                    Longitude AS X,
                    Latitude AS Y 
                FROM ev_route_optimization.mm_evcharging
            ),
            OPTIONS => KV_PAIRS(max_solution_radius = '2400')
        )
    );
    -- Step 2: Run the inverse shortest path solver from all EV charging stations to the destination
    CREATE OR REPLACE TABLE ev_route_optimization.charging_to_dest_path AS
    SELECT * 
    FROM TABLE (
        SOLVE_GRAPH
        (
            GRAPH => 'ev_route_optimization.mm_lakes',
            SOLVER_TYPE => 'INVERSE_SHORTEST_PATH',
            SOURCE_NODES => INPUT_TABLE(
                SELECT ST_GEOMFROMTEXT(dest_pt) AS WKTPOINT 
                FROM ev_route_optimization.source_dest 
                ORDER BY TIMESTAMP DESC -- Find the latest destination record
                LIMIT 1
            ),
            DESTINATION_NODES => INPUT_TABLE(
                SELECT 
                    Longitude AS X,
                    Latitude AS Y 
                FROM ev_route_optimization.mm_evcharging
            )
        )
    );
    -- Step 3: Find the combined path that minimizes the cost from source to destination with a stop at an EV charging station
    
    INSERT INTO ev_route_optimization.optimal_route /* ki_hint_update_on_existing_pk */  
    SELECT * 
    FROM
    (
        WITH temp (id_with_min_cost) AS
        (
            SELECT arg_min(s1+s2,id1) as id_with_min_cost FROM
                (SELECT  SOLVERS_NODE_COSTS as s1, SOLVERS_NODE_ID as id1, * from ev_route_optimization.source_to_charging_path),
                (SELECT  SOLVERS_NODE_COSTS as s2, SOLVERS_NODE_ID as id2, * from ev_route_optimization.charging_to_dest_path)
            WHERE id1 = id2
        )
        SELECT 
            1 as pk_id,     --this is the primary key so we will always be overwriting this record
            s1.wktroute as wkt1,
            s2.wktroute as wkt2,
            st_linemerge(st_collect(s1.wktroute,s2.wktroute)) as wkt_full
        FROM 
            ev_route_optimization.source_to_charging_path s1, 
            ev_route_optimization.charging_to_dest_path s2,
            temp 
        WHERE 
            s1.SOLVERS_NODE_ID = temp.id_with_min_cost and
            s2.SOLVERS_NODE_ID = temp.id_with_min_cost
    );
END 
EXECUTE FOR EVERY 5 SECONDS;
/* SQL Block End */


/* TEXT Block Start */
/*
SELF REFRESHING MAP SHOWING THE SHORTEST PATH FROM SOURCE TO ALL EV STATIONS (WITHIN 2400 SECS)
The map below is set to refresh every 2 secs to show updated paths based on latest source destination.
✎ NOTE
: The table that is referenced might be missing occassionally (API error) because the map refresh might coincide with the execution of the stored procedure. Occasionally, there might not be a path shown on the map below (even when there is no error). This is because the current source point doesn't have an EV charging station that is within 40 minutes from it.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
MAP SHOWING THE SHORTEST PATH FROM  ALL EV STATIONS TO THE LATEST DESTINATION
This map updates every 2 seconds.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
MAP SHOWING THE COMBINED PATH
The path below shows the shortest path between the source and the destination point with a stop at a charging station that is within 40 minutes of the source point.
*/
/* TEXT Block End */


/* Worksheet: Clean up sheet */
/* Worksheet Description: Description for sheet 5 */


/* SQL Block Start */
-- Drop the table with the streaming ingest so that we can drop the schema and all the other tables in it.
DROP TABLE ev_route_optimization.source_dest;

-- Drop schema and all its contents
DROP SCHEMA IF EXISTS ev_route_optimization CASCADE;
/* SQL Block End */

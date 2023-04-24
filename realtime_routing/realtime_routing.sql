/* Workbook: Real time routing with graphs */
/* Workbook Description: Find the shortest path between points while considering real time information on traffic */


/* Worksheet: Load data */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
REGISTER THE DATA SOURCES
We are loading data from two different data sources - AWS S3 and Apache Kafka. The queries below register these two data sources.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create AWS S3 data source
CREATE OR REPLACE DATA SOURCE examples_s3
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
DROP TABLE IF EXISTS dc_roads;

-- Create the credentials for the kafka cluster
CREATE OR REPLACE CREDENTIAL dc_traffic_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'QZN62QB2RBTLW74L',
   'sasl.password' = 'iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- Create the quote source
CREATE OR REPLACE DATA SOURCE traffic_stream
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'dc_traffic_weights',
    credential = 'dc_traffic_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA
The queries below load the two static data sets from AWS S3 and the streaming data from Kafka into Kinetica.
1.
DC road network data
: This CSV file on AWS S3 contains spatial data (WKT linestrings) that describe roads in Washington DC along with additional information on the direction (one-way vs. two-way), distance and average time for traversing each segment.
2.
A list of source points
: This CSV file on AWS S3 contains a set of starting points for each trip to Union Station. We select one point from this list at random when executing the solver in real time.
3.
Traffic weights data
: This is a stream of fake traffic data associated with each edge in the DC road network that I have set up using Kafka. Each message in the Kafka topic consists of an edge ID that corresponds to the id in the DC road network data and an associated traffic weight. Note that this data is fake. I have generated it so as to show the effects of applying real time weights when solving a routing problem.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Load the data into the dc roads table in Kinetica
LOAD DATA INTO dc_roads
FROM FILE PATHS 'dc/dc_roads_truncated.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_s3'
);

-- Load the source points for the trips
LOAD DATA INTO source_points
FROM FILE PATHS 'dc/source_points.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_s3'
);
/* SQL Block End */


/* SQL Block Start */
-- Load the traffic weights data from Kafka
LOAD DATA INTO traffic_weights
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'traffic_stream',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_offset_reset_policy = 'latest', -- load the latest qoutes data
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* Worksheet: Create the graph */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
CREATE GRAPH
The query below creates a directed graph of the DC road network. The default weights are set as the time divided by the number of points in each WKTLINE.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH dc_graph
( 
    EDGES => INPUT_TABLE 
    (
        SELECT  id  AS ID,
        wkt AS WKTLINE,                                            
        dir AS DIRECTION,
        time/(ST_numPoints(wkt)-1) AS WEIGHT_VALUESPECIFIED
        FROM dc_roads
    ),
    OPTIONS => KV_PAIRS
    ( 
        graph_table = 'dc_graph_table'
    )
);
/* SQL Block End */


/* Worksheet: Weights */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
CALCULATE THE WEIGHTS
The queries below identify the appropriate weights that can be applied when solving the DC graph. The first view below (recent_weights) identifies the most recent observation for each id. The second view joins the most recent observations with the spatial data and calculates the correct traffic cost (after dividing by the number of points in each WKTLINE.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW recent_weights 
REFRESH EVERY 1 SECOND AS 
SELECT 
    id,
    ARG_MAX(timestamp, traffic_cost) as traffic_cost,
    MAX(timestamp) AS timestamp
FROM traffic_weights
GROUP BY id;
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW weights_mapped 
REFRESH ON CHANGE AS 
SELECT 
    rw.id,
    wkt,
    time,
    rw.traffic_cost/(ST_numPoints(wkt)-1) as traffic_cost
FROM recent_weights rw, dc_roads d 
WHERE rw.id = d.id;
/* SQL Block End */


/* Worksheet: Solve using real time weights */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
SOLVE
The SQL procedure below is executed every 10 seconds with a new randomly selected starting point. It runs two solvers the first with the new weights and the second with the default weights. The map compares the results from the two solvers. The one with the updated weights is shown in red while the default one is shown in blue. You can refresh it to see the updated routes every 10 seconds.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE PROCEDURE shortest_path_updater
BEGIN

CREATE OR REPLACE TABLE source_point AS 
SELECT source AS WKTPOINT 
FROM source_points 
ORDER BY RAND() 
LIMIT 1;

CREATE OR REPLACE TABLE path_with_weight AS
SELECT * FROM TABLE 
(
    SOLVE_GRAPH
    (
        GRAPH => 'dc_graph',
        SOLVER_TYPE => 'SHORTEST_PATH',
        SOURCE_NODES => INPUT_TABLE(SELECT WKTPOINT FROM source_point),
        DESTINATION_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT('POINT (-77.0074811 38.8976992)') AS WKTPOINT),
        WEIGHTS_ON_EDGES => INPUT_TABLE
        (
           SELECT 
                id AS EDGE_ID,                                 
                traffic_cost AS VALUESPECIFIED
            FROM hsubhash_kinetica.weights_mapped
        )
    )

);

CREATE OR REPLACE TABLE path_without_weights AS
SELECT * FROM TABLE 
(
    SOLVE_GRAPH
    (
        GRAPH => 'dc_graph',
        SOLVER_TYPE => 'SHORTEST_PATH',
        SOURCE_NODES => INPUT_TABLE(SELECT WKTPOINT FROM source_point),
        DESTINATION_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT('POINT (-77.0074811 38.8976992)') AS WKTPOINT)      
    )
);

END
EXECUTE FOR EVERY 10 SECONDS;
/* SQL Block End */

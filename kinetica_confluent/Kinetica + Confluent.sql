/* Workbook: Kinetica + Confluent */
/* Workbook Description: Description for Kinetica + Confluent */


/* Worksheet: Load data */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCE
Use the API key name and secret to create the credentials required to access the Confluent cluster. Use the credentials along with the location of the confluent cluster and the topic name to create the data source.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Credentials for Kafka cluster
CREATE OR REPLACE CREDENTIAL confluent_creds
TYPE = 'kafka'
WITH OPTIONS (
    'security.protocol' = 'SASL_SSL',
    'sasl.mechanism' = 'PLAIN',
    'sasl.username'='QZN62QB2RBTLW74L',
    'sasl.password'='iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- Create the data source for vehicle locations
CREATE OR REPLACE DATA SOURCE vehicle_locations_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS (
    'kafka_topic_name' =  'vehicle_locations',
    credential = 'confluent_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA INTO A TABLE IN KINETICA
Now that the data source is set up we can load data from it into a table in Kinetica.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS vehicle_locations;
-- Load data
LOAD DATA INTO vehicle_locations
FROM FILE PATH ''
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'vehicle_locations_source',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE FENCES DATA
This data is hosted as a CSV file in an S3 bucket. The queries below register the data source and load the data from the csv file.
*/
/* TEXT Block End */


/* SQL Block Start */
-- The AWS S3 bucket
CREATE OR REPLACE DATA SOURCE examples_data
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);

-- Load the fences data into Kinetica
DROP TABLE IF EXISTS dc_fences;
CREATE OR REPLACE TABLE dc_fences 
(
    fence_id int,
    wkt geometry,
    fence_label varchar(32)
);
LOAD DATA INTO dc_fences
FROM FILE PATHS 'landmark_fences.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_data'
);
/* SQL Block End */


/* Worksheet: Geofencing events */
/* Worksheet Description: Description for sheet 2 */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW fence_events 
REFRESH ON CHANGE AS 
SELECT 
    TRACKID, 
    wkt, 
    x, 
    y, 
    TIMESTAMP, 
    CONCAT(CHAR16(TRACKID), CONCAT(' is at ', fence_label)) as event_text 
FROM vehicle_locations, dc_fences
WHERE 
    STXY_DWITHIN(x, y, wkt, 200, 1) = 1 AND 
    TIMESTAMP > NOW() - INTERVAL '10' MINUTE;
/* SQL Block End */


/* Worksheet: Stream events */
/* Worksheet Description: Description for sheet 3 */


/* SQL Block Start */
CREATE OR REPLACE DATA SINKconfluent_sink
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS (
    'kafka_topic_name' =  'fence_events',
    credential = 'confluent_creds'
);
/* SQL Block End */


/* SQL Block Start */
-- CREATE A STREAM 
CREATE STREAM fence_events ON fence_events  
REFRESH ON CHANGE
WITH OPTIONS 
(
    DATASINK_NAME = 'confluent_sink'
);
/* SQL Block End */

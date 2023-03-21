/* Workbook: Materialized views in Kinetica */
/* Workbook Description: Description for Materialized views in Kinetica */


/* Worksheet: 1. Data setup (DDL) */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
SETUP THE DATA SOURCE
The SQL statements below create a credential and then use that to connect to the Kafka topic that is streaming ship locations.
ABOUT THE DATA
The Kafka streams is setup to simulate a real time stream of ship locations over the last 2 days.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop the table into which we will be streaming (if it exists) so that we can recreate the credential
DROP TABLE IF EXISTS ship_tracks;

-- Create the credentials for the kafka cluster
CREATE OR REPLACE CREDENTIAL ship_confluent_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'QZN62QB2RBTLW74L',
   'sasl.password' = 'iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- Create the data source
CREATE OR REPLACE DATA SOURCE ships_stream_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'ais_tracks',
    credential = 'ship_confluent_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA
Next we define the table and start loading data from the kafka cluster. Kinetica starts by loading the first message in the topic (about 2 days old) till it catches up with the most recent message (i.e. the current location of ships).
The map below is set to refresh automatically once every 2 seconds, so you can see the tracks develop on the map as the data streams in.
⚠️
NOTE:
The data for the Kafka topic is generated using a seed file that contains about 4 days worth of Track data. So you might start seeing Tracks that are repeated if you keep Kinetica running for more than that period. This might yield unexpected results when analyzing Tracks.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the table for the ais data
CREATE OR REPLACE TABLE ship_tracks
(
    "TIMESTAMP" TIMESTAMP NOT NULL,
    "CONTINENT" VARCHAR (64, dict),
    "COUNTRY" VARCHAR (32, dict),
    "TRACKID" VARCHAR (shard_key, 64),
    "NAVIGATION_STATUS" VARCHAR (64, dict),
    "y" REAL,
    "x" REAL,
    "SHIP_TYPE" VARCHAR (64, dict)
);

-- Load the data from the kafka data source into the table
LOAD DATA INTO ship_tracks
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'ships_stream_source',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* Worksheet: Materialized views */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
CALCULATE TRACK LENGTHS
The ST_TRACKLENGTH calculates the length of tracks in meters. The view is set to refresh on change.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW track_lengths
REFRESH ON CHANGE AS
SELECT 
    TRACKID, 
    ROUND(ST_TRACKLENGTH(Y, X,TIMESTAMP, 1) / 1000) AS track_length_km
FROM ship_tracks
GROUP BY TRACKID;
/* SQL Block End */


/* TEXT Block Start */
/*
IDENTIFY LONGEST TRACKS
The query below filters tracks for the longest tracks in the track_lengths view. This query is also set to refresh on change.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW track_render_data 
REFRESH ON CHANGE AS 
SELECT TRACKID, x, y, TIMESTAMP 
FROM ship_tracks
WHERE TRACKID IN (SELECT TRACKID FROM track_lengths ORDER BY track_length_km DESC LIMIT 5);
/* SQL Block End */

/* Workbook: Tracking entities in real time */
/* Workbook Description: This workbook uses a small sample of the AIS data to track entities in real time. */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
THE PROBLEM
Let's say you work for the US Coast Guard Service in the Gulf of Mexico region. Your job is to monitor ship traffic in the area to alert whenever the following events happen.
-- When a ship enters certain areas within the Gulf of Mexico region
-- Identify which ships are dwelling or loitering (not moving) within this area of interest
-- When ships are passing too close to other ships (proximity alerts)
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create a temp table to show the area on a map.
CREATE OR REPLACE TEMP TABLE area_interest AS 
SELECT ST_MAKEENVELOPE(-98.66,18.09,-76.89,30.26);
/* SQL Block End */


/* Worksheet: Data setup (DDL) */
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
DROP TABLE IF EXISTS ais_tracks_stream;

-- Create the credentials for the kafka cluster
CREATE OR REPLACE CREDENTIAL ais_confluent_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'FKHU5OKQSM6J3FZY',
   'sasl.password' = 'BT0b0049Q016ncuMUD0Pt5bRPr6YZu9YNioEtGqfuaN1pPmwyPUVMytUWloqtt8o'
);

-- Create the data source
CREATE OR REPLACE DATA SOURCE ais_stream_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'ais_tracks',
    credential = 'confluent_cred'
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
CREATE OR REPLACE TABLE ais_tracks_stream
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


LOAD DATA INTO ais_tracks_stream
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'ais_stream_source',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_group_id = 'ais_tracks_grp_6'
);
/* SQL Block End */


/* SQL Block Start */
SELECT COUNT(*) FROM ais_tracks_stream
WHERE TIMEBOUNDARYDIFF('HOUR', TIMESTAMP, NOW()) > 44;
/* SQL Block End */


/* Worksheet: Tracks */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
WHAT ARE TRACKS?
A track is a
native
geospatial object in Kinetica that is used to represent the path an object takes over time and space. A track is defined using an ID, x and y coordinates and timestamps.
WHY ARE TRACKS USEFUL?
Pretty much any object that moves can be represented and studied using tracks. This has a wide range of application in almost all sectors of the economy including supply chain management, ride sharing, IoT devices.
WHAT SETS KINETICA APART?
Tracks are unique to Kinetica and they are represented as a native geospatial object in the database. There are several advantages to this.
-- When a track is defined, Kinetica, automatically interpolates between the points to construct the path that constitutes the track.
-- This interpolation to a path allows Kinetica to perform geospatial operations that detect intersections, collisions, proximity with other geospatial objects and measure track features such as its length and duration.
All of this out of the box functionality makes it easier and more performant to use Kinetica to analyze the behaviour of tracks without having to write any custom code yourself.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CALCULATE THE SUMMARY TRACKS
Tracks come with two aggregate functions ST_TRACKLENGTH and ST_TRACKDURATION. Let's use those to calculate track lengths, duration and bounds.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE track_summary AS
SELECT 
    TRACKID, 
    COUNT(*) AS n_obs, 
    ROUND(ST_TRACKLENGTH(Y, X,TIMESTAMP, 1) / 1000) AS track_length_km, 
    ROUND(ST_TRACKDURATION(HOUR,TIMESTAMP)) as DURATION,
    ROUND((ST_TRACKLENGTH(x,y,TIMESTAMP,1) / 1000)/ST_TRACKDURATION(HOUR,TIMESTAMP)) as AVG_SPEED_KM_HRS,
    MIN(X) AS min_longitude,
    MAX(X) AS max_longitude,
    MIN(Y) AS min_latitude,
    MAX(Y) AS max_latitude
FROM ais_tracks_stream
GROUP BY TRACKID
ORDER BY track_length_km DESC;

SELECT * FROM track_summary;
/* SQL Block End */


/* TEXT Block Start */
/*
VISUALIZE THE 40 LONGEST TRACKS ON A MAP
Let's pick a random track from the 40 longest tracks in the data to study more closely on the map using a materialized view that refreshes every 5 seconds.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE long_tracks AS 
SELECT TRACKID 
FROM track_summary
LIMIT 40;

CREATE OR REPLACE MATERIALIZED VIEW single_track 
REFRESH EVERY 5 SECONDS
AS 
SELECT * 
FROM ais_tracks_stream
WHERE TRACKID = (SELECT TRACKID FROM long_tracks ORDER BY RAND() LIMIT 1);
/* SQL Block End */


/* Worksheet: Geofencing */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
GEOFENCING ALERTS
Now that we have the data setup let's look at some of the common use cases with Tracks. The first use case we will explore is that for geofencing. Let's say there are certain areas in the Gulf of Mexico that are more prone to inclement weather. You would like to keep a closer eye on ships that enter this area. We can use the ST_TRACKINTERSECTS method to setup an alert whenever a ship enters this region.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Show the geo fence on a map
CREATE OR REPLACE TABLE geo_fence AS 
SELECT 
    1 as zone_id, 
    ST_MAKETRIANGLE2D( -90, 29, -94, 27, -86, 26) as monitor_zone;
/* SQL Block End */


/* TEXT Block Start */
/*
ST_TRACKINTERSECTS
Kinetica interpolates the path that a track will take based on the ordering of the points. The ST_TRACKINTERSECTS function takes this interpolation into account when determining whether a track intersects with a fence.
The output from the function contains the TRACKID, the entire track linestring and information about the geofence that it intersected with.
The code below uses a materialized view that is refreshed every 5 seconds to identify tracks as they intersect with the fence that we defined above. We are only looking for tracks that intersected the fence over the last 2 hours.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW recent_tracks 
REFRESH EVERY 5 MINUTES
AS 
SELECT * FROM ais_tracks_stream
WHERE TIMEBOUNDARYDIFF('HOUR', TIMESTAMP, NOW()) < 4;
/* SQL Block End */


/* SQL Block Start */
-- A materialized view of all the paths that have intersected with the fence over the last two hours
CREATE OR REPLACE MATERIALIZED VIEW fence_tracks
REFRESH EVERY 5 SECONDS AS
SELECT *
FROM TABLE
(
    ST_TRACKINTERSECTS
    (
        TRACK_TABLE => INPUT_TABLE(recent_tracks),
        TRACK_ID_COLUMN => 'TRACKID',
        TRACK_X_COLUMN => 'x',
        TRACK_Y_COLUMN => 'y',
        TRACK_ORDER_COLUMN => 'TIMESTAMP',
        GEOFENCE_TABLE => INPUT_TABLE(geo_fence),
        GEOFENCE_ID_COLUMN => 'zone_id',
        GEOFENCE_WKT_COLUMN => 'monitor_zone'
    )
);
/* SQL Block End */


/* SQL Block Start */
-- Get the full path of all the tracks that intersected with the fence over the last 2 hours
CREATE OR REPLACE MATERIALIZED VIEW fence_track_paths
REFRESH ON CHANGE 
AS 
SELECT * FROM ais_tracks_stream
WHERE TRACKID IN (SELECT TRACKID FROM fence_tracks);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE AN ALERT
The materialized view that was setup earlier does all the work of monitoring the incoming data to automatically detect anytime a track intersects with our geofence. Now all we need to do is to direct that information out of Kinetica so that the end use is alerted as soon an event of interest occurs.
There are a few different ways to do this. We could set up a Kafka topic as a data sink that receives all new records from the portfolio alert table that we created in the previous sheet or can use webhooks to setup alerts to messaging tools like Slack or custom applications.
For this demo, we recommend using the website: https://webhook.site/ to generate a webhook URL. Copy the webhook URL and paste it as the destination in the stream below. This will send alerts to that URL any time a track intersects with the geofence.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Setup an alert sink
CREATE STREAM geofence_alerts ON fence_tracks
REFRESH ON CHANGE 
WITH OPTIONS 
(
    DESTINATION = 'PASTE WEBHOOK' --- Generate a webhook URL and paste here
);
/* SQL Block End */


/* Worksheet: Dwell Times */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
ALERT BASED ON DWELL AND/OR LOITERING
As a port manager you also want to know when a vessel is spending more time than usual without moving or circling around the same spots. We are interested in just the last 4 hours of activity. So let's start by identifying tracks that have timestamps in the last 4 hours and calculating the area of the bounds of that track and the length.

I have set the materialized view to update every 10 minutes since we don't need to
*/
/* TEXT Block End */


/* SQL Block Start */
-- Identify the track length and the bounds of the tracks that have recordings for the last 4 hours.
CREATE OR REPLACE MATERIALIZED VIEW track_area_length_4hr
REFRESH EVERY 10 MINUTES AS 
SELECT 
    TRACKID,
    ST_AREA(ST_MAKEENVELOPE(MIN(X), MIN(Y), MAX(X), MAX(Y))) AS track_bounds_area,
    ST_TRACKLENGTH(Y, X,TIMESTAMP, 1) AS track_length
FROM (SELECT * FROM recent_tracks)
GROUP BY TRACKID
ORDER BY track_bounds_area;

SELECT * FROM track_area_length_4hr;
/* SQL Block End */


/* TEXT Block Start */
/*
DWELLING VS LOITERING
Dwelling is when a object is almost entirely stationary. For instance, a ship that has dropped anchor will barely move until it lifts its anchor. So we'd expect the track length and the area that it covers to be pretty small for the period that it is dwelling.
Loitering on the other hand is when an  is constantly moving but within a small area. So in the case of dwelling, we'd expect the track length to be significantly greater than zero but the area that it covers (based on the bounds) to be pretty small.
Let's start by finding all the ships that are dwelling. Our threshold for dwelling is an bounds area less than 100 metre squared and a track length less than 100 metres total over the last 4 hours.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Find all the tracks that are dwelling
CREATE OR REPLACE MATERIALIZED VIEW dwelling_ships
REFRESH EVERY 5 MINUTES AS 
SELECT * FROM recent_tracks
WHERE TRACKID IN 
(
    SELECT TRACKID FROM track_area_length_4hr
    WHERE track_bounds_area < 100 AND track_length < 100
);
/* SQL Block End */


/* TEXT Block Start */
/*
Click the refresh button to see the ships that are dwelling.
🔎 Try zooming down to a 5 metre level to see how the track looks up close.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Next, lets calculate loitering. The threshold for loitering is that a ship has a total track length between 1 to 5 kms within a 400 metre square area.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Find all the tracks that are loitering
CREATE OR REPLACE MATERIALIZED VIEW loitering_ships
REFRESH EVERY 5 MINUTES AS 
SELECT * FROM recent_tracks 
WHERE TRACKID IN 
(
    SELECT TRACKID FROM track_area_length_4hr
    WHERE track_bounds_area < 400 AND track_length BETWEEN 1000 AND 5000
);
/* SQL Block End */


/* TEXT Block Start */
/*
Click the refresh button on the map to see the Tracks that are loitering.
🔎 Zoom into the map to see the loitering tracks up close.
*/
/* TEXT Block End */


/* Worksheet: Proximity */
/* Worksheet Description:  */


/* TEXT Block Start */
/*
ALERT BASED ON PROXIMITY
Detect when two tracks are within a certain distance from each other around the same time. Kinetica has an ST_DWITHIN function that can be used to detect when a tracks are within a particular distance and time from each other.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Identify tracks that came within 2 meters of each other within a 1 minute window
CREATE OR REPLACE MATERIALIZED VIEW proximate_tracks 
REFRESH EVERY 1 MINUTE AS 
SELECT * FROM TABLE 
(
    ST_TRACK_DWITHIN
    (
        TRACK_TABLE => INPUT_TABLE(recent_tracks),
        TRACK_ID_COLUMN => 'TRACKID',
        TRACK_X_COLUMN =>  'x',
        TRACK_Y_COLUMN =>  'y',
        TRACK_ORDER_COLUMN =>  'TIMESTAMP',
        SEARCH_TABLE => INPUT_TABLE(recent_tracks),
        SEARCH_ID_COLUMN =>  'TRACKID',
        SEARCH_X_COLUMN =>  'x',
        SEARCH_Y_COLUMN =>  'y',
        SEARCH_ORDER_COLUMN =>  'TIMESTAMP',
            SEARCH_XY_DISTANCE => '2',
            SPATIAL_SOLUTION_TYPE => 1,
            SEARCH_TIME_DISTANCE => '1m'
    )
)
WHERE TRACK_TABLE_TRACKID <> SEARCH_TABLE_TRACKID;
/* SQL Block End */


/* TEXT Block Start */
/*
The queries below are optional. They select two proximate tracks at random from the materialized view created above to display on the map.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW single_proximates 
REFRESH EVERY 5 SECONDS AS 
SELECT * FROM proximate_tracks
ORDER BY RAND()
LIMIT 1;
CREATE OR REPLACE MATERIALIZED VIEW map_proximates 
REFRESH EVERY 5 SECONDS AS
SELECT * from recent_tracks
WHERE TRACKID = (SELECT TRACK_TABLE_TRACKID FROM single_proximates) OR
TRACKID = (SELECT SEARCH_TABLE_TRACKID FROM single_proximates);
/* SQL Block End */


/* TEXT Block Start */
/*
The map below shows tracks that at some point in the last 4 hours passed within 2 metres of each other within a 1 minute window.
*/
/* TEXT Block End */

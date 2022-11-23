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
    ERROR_HANDLING = 'permissive'
);
/* SQL Block End */


/* Worksheet: 2. Tracks */
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
CREATE OR REPLACE MATERIALIZED VIEW track_summary 
REFRESH EVERY 2 MINUTES AS
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
FROM ship_tracks
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
CREATE OR REPLACE MATERIALIZED VIEW long_tracks
REFRESH ON CHANGE AS
SELECT TRACKID 
FROM track_summary
LIMIT 40;

-- Select a random track to display on the map
CREATE OR REPLACE MATERIALIZED VIEW single_track 
REFRESH EVERY 5 SECONDS
AS 
SELECT TRACKID, x, y, TIMESTAMP 
FROM ship_tracks
WHERE TRACKID = (SELECT TRACKID FROM long_tracks ORDER BY RAND() LIMIT 1);
/* SQL Block End */


/* Worksheet: 3. Geofencing */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
GEOFENCING ALERTS
We are expecting bad weather around New Orleans. You have been tasked with setting up a way to alert ships that are traveling too fast in this area. The threshold is set as  ships that have traveled more than two kilometers over the last 5 minutes.
The zone around New Orleans is shown below.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Show the geo fence on a map
CREATE OR REPLACE TABLE geo_fence AS 
SELECT 
    1 as zone_id, 
    ST_MAKEENVELOPE( -91, 28.5, -88.5, 30.5) as monitor_zone;
/* SQL Block End */


/* TEXT Block Start */
/*
First we need to setup a view that calculates the distance moved by all ships in the last 5 minutes.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Calculate the distance traveled over the last 5 minutes
CREATE OR REPLACE MATERIALIZED VIEW track_length_5mins
REFRESH ON CHANGE AS
SELECT 
    TRACKID, 
    ST_TRACKLENGTH(Y, X,TIMESTAMP, 1) / 1000 AS track_length 
FROM ship_tracks 
WHERE TIMEBOUNDARYDIFF('MINUTE', TIMESTAMP, NOW()) < 5
GROUP BY TRACKID;

-- Show the ships that are traveling fast
SELECT TRACKID FROM track_length_5mins WHERE track_length > 2;
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
-- Set up a view with all the fast moving tracks (we want to look for intersections anytime over the past 4 hours with the zone of interest)
CREATE OR REPLACE MATERIALIZED VIEW moving_tracks
REFRESH ON CHANGE AS 
SELECT * FROM ship_tracks 
WHERE 
    TRACKID IN (SELECT TRACKID FROM track_length_5mins WHERE track_length > 2) AND 
    TIMEBOUNDARYDIFF('HOUR', TIMESTAMP, NOW()) < 4;
/* SQL Block End */


/* SQL Block Start */
-- A materialized view of all the paths from the view above that have intersected with the zone
CREATE OR REPLACE MATERIALIZED VIEW fence_tracks
REFRESH ON CHANGE AS
SELECT *
FROM TABLE
(
    ST_TRACKINTERSECTS
    (
        TRACK_TABLE => INPUT_TABLE(moving_tracks),
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
-- View to show all the fast moving ships that have intersected with the geofence
CREATE OR REPLACE MATERIALIZED VIEW fence_track_paths
REFRESH ON CHANGE 
AS 
SELECT * FROM moving_tracks
WHERE TRACKID IN (SELECT TRACKID FROM fence_tracks);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE AN ALERT
The materialized view that was setup earlier does all the work of monitoring the incoming data to automatically detect anytime a track intersects with our geofence. Now all we need to do is to direct that information out of Kinetica so that the end use is alerted as soon an event of interest occurs.
There are a few different ways to do this. We could set up a Kafka topic as a data sink that receives all new records from the portfolio alert table that we created in the previous sheet or can use webhooks to setup alerts to messaging tools like Slack or custom applications.
We are using slack for this demo.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW slack_alert_text
REFRESH ON CHANGE AS 
SELECT CONCAT(TRACKID, ' has moved more than 2 Kms inside the weather zone in the last 5 mins❗️') as text 
FROM fence_tracks;
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SINK slack_alerts
LOCATION = 'https://hooks.slack.com/services/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';
/* SQL Block End */


/* SQL Block Start */
-- Setup an alert sink
CREATE STREAM geofence_alerts ON slack_alert_text
REFRESH ON CHANGE 
WITH OPTIONS 
(
    DATASINK_NAME = 'slack_alerts'
);
/* SQL Block End */


/* Worksheet: 4. Dwell Times */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
ALERT BASED ON DWELL AND/OR LOITERING
As a port manager you also want to know when a vessel is spending more time than usual without moving or circling around the same spots. We are interested in just the last 4 hours of activity. So let's start by identifying tracks that have timestamps in the last 4 hours and calculating the area of the bounds of that track and the length.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create a view with the tracks over the last 4 hours
CREATE OR REPLACE MATERIALIZED VIEW recent_tracks
REFRESH EVERY 5 MINUTES AS
SELECT * 
FROM ship_tracks 
WHERE TIMEBOUNDARYDIFF('MINUTE', TIMESTAMP, NOW()) < 5;

-- Identify the track length and the bounds of the tracks that have recordings for the last 4 hours.
CREATE OR REPLACE MATERIALIZED VIEW track_area_length_4hr
REFRESH EVERY 5 MINUTES AS 
SELECT 
    TRACKID,
    ABS(MAX(X) - MIN(X)) AS x_dist,
    ABS(MAX(Y) - MIN(Y)) AS y_dist,
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
Loitering on the other hand is when an  is constantly moving but within a small area. So in the case of dwelling, we'd expect the track length to be significantly greater than zero but the area that it covers (based on the bounds) to be pretty small. Loitering in this context could mean a ship which is performing a particular kind of activity like fishing.
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
    WHERE (x_dist < 0.01 AND y_dist < 0.01) AND track_length < 50
);
/* SQL Block End */


/* TEXT Block Start */
/*
👆🏻Click the refresh button to see the ships that are dwelling.
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
    WHERE (x_dist < 0.01 AND y_dist < 0.01) AND track_length > 1000
);
/* SQL Block End */


/* TEXT Block Start */
/*
Click the refresh button on the map to see the Tracks that are loitering.
🔎 Zoom into the map to see the loitering tracks up close.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
SET UP AN ALERT
Go ahead and clone this example to your workspace if you are running this on read only mode (example) to complete the next steps.
In the previous worksheet we set up an alert by first setting up a Data Sink that was configured to send messages to a Slack channel. Follow the instructions here to set up a slack app and use that to send messages to a channel on you workspace whenever dwelling or loitering ships are identified.. https://api.slack.com/messaging/webhooks.
If you don't have access to Slack, you can follow the instructions from one of other examples to set up an alerting system via webhook . Try the "Time Series Joins With ASOF" example.
*/
/* TEXT Block End */


/* Worksheet: 5. Proximity */
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
-- Select a random row from the proximate tracks
CREATE OR REPLACE MATERIALIZED VIEW single_proximates 
REFRESH EVERY 5 SECONDS AS 
SELECT * FROM proximate_tracks
ORDER BY RAND()
LIMIT 1;

-- Create a view of proxiamte tracks to show on map (one at a time)
CREATE OR REPLACE MATERIALIZED VIEW map_proximates 
REFRESH EVERY 5 SECONDS AS
SELECT * from ship_tracks
WHERE TRACKID = (SELECT TRACK_TABLE_TRACKID FROM single_proximates) OR
TRACKID = (SELECT SEARCH_TABLE_TRACKID FROM single_proximates);
/* SQL Block End */


/* TEXT Block Start */
/*
The map below shows tracks that at some point in the last 4 hours passed within 2 metres of each other within a 1 minute window. Most of these will likely be tug boats.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
SET UP AN ALERT
Go ahead and clone this example to your workspace if you are running this on read only mode (example) to complete the next steps.
Set up a slack app and use that to send messages to a channel on you workspace whenever proximity events occur (https://api.slack.com/messaging/webhooks).
If you don't have access to Slack, you can follow the instructions from one of other examples to set up an alerting system via webhook . Try the "Time Series Joins With ASOF" example.
*/
/* TEXT Block End */


/* Worksheet: ❗️6. Pause subscription */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
PAUSE SUBSCRIPTIONS
The Kafka topic that we are subscribed to is always on. So data will continue to load into the connected Kinetica table unless we pause the subscription. You can follow the instructions here (https://docs.kinetica.com/7.1/sql/ddl/#manage-subscription) to resume your subscription anytime you would like to.
*/
/* TEXT Block End */


/* SQL Block Start */
ALTER TABLE ship_tracks
PAUSE SUBSCRIPTION ships_stream_source;
/* SQL Block End */

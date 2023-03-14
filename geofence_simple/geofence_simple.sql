/* Workbook: A simple illustration of geofencing */
/* Workbook Description: This workbook illustrates a typical example of Kinetica can be used to setup a geofence */


/* Worksheet: Introduction */
/* Worksheet Description: A description of this workbook */


/* TEXT Block Start */
/*
👇 NOTE
The spatial analytics example workbook offers a more comprehensive look at Kinetica's spatial capabilities (including geofencing). Use that for a deeper dive.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
This workbook illustrates the concept of geofencing using Kinetica.
WHAT IS GEOFENCING?
Geofencing is the ability to classify an object as being inside a defined geographical boundary.
WHAT IS A COMMON USECASE FOR GEOFENCING?
The most common use case for geofencing is to trigger an event (for instance an alert) when an object is inside or outside the fence. Some examples include,
1. Triggering an alert when a vehicle enters a restricted zone,
2. Alerting a customer when a delivery truck carrying a package is within a certain distance from their home
3. Sending alerts to a customer when they are close to certain locations they may be interested in visiting
HOW DOES THIS EXAMPLE WORK?
This example illustrates the first use case described above. Our data input for this example is a stream via Kafka of vehicle locations (6 vehicles). We are interested in knowing when a particular vehicle (vehicle 5) is inside a certain zone of interest in downtown Washington DC. For illustration purposes, we will stream the alerts to a webhook but you can alternatively set these up to be registered via kafka or any other custom application like Slack (via webhooks).
*/
/* TEXT Block End */


/* Worksheet: Data setup (DDL) */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
CREATE THE SCHEMA FOR THE EXAMPLE
Kinetica uses schema's to organize tables. It is good practice to have a schema defined for each project. Tables that are created without an explicit schema assignment are placed in the default schema ki_home.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
LOAD THE DATA
We will be using a stream of vehicle locations. The steps for loading this data are as follows.
1. Define the table
2. Set up the credentials for connecting to the kafka cluster (Optional)
3. Define the data source
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE vehicle_locations
(
    x float,
    y float,
    TRACKID varchar(64),
    DEPOT_ID integer,
    sids integer,
    TIMESTAMP timestamp,
    shard_key(TRACKID)
);
/* SQL Block End */


/* SQL Block Start */
-- Credentials for the kafka cluster
CREATE OR REPLACE CREDENTIAL confluent_creds
TYPE = 'kafka'
WITH OPTIONS (
    'security.protocol' = 'SASL_SSL',
    'sasl.mechanism' = 'PLAIN',
    'sasl.username'='QZN62QB2RBTLW74L',
    'sasl.password'='iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE vehicle_locations_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS (
    'kafka_topic_name' =  'vehicle_locations',
    credential = 'confluent_creds'
);
/* SQL Block End */


/* SQL Block Start */
-- Start loading the data into the previously defined table
LOAD DATA INTO vehicle_locations
FROM FILE PATH ''
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'vehicle_locations_source',
    KAFKA_GROUP_ID = 'BH_90210',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* Worksheet: Geofencing */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
VISUALIZE THE VEHICLE LOCATIONS
Let's start by getting a sense for the location and movement of the vehicles. The speed of the vehicle is a bit accelerated for the demo for illustration purposes.
We will be specifically looking at vehicle 5. So we will start by setting up a materialized view which refreshes every 5 seconds to record new locations that are streaming in. The map below show the vehicle moving through downtown area in DC.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create a materialized view that refreshes every 5 seconds to register location of truck number 5
CREATE OR REPLACE MATERIALIZED VIEW vehicle_5
REFRESH EVERY 5 SECONDS AS
SELECT * 
FROM vehicle_locations
WHERE TRACKID = '5';
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE A ZONE OF INTEREST
ST_MAKEENVELOPE() is a function from Kinetica's geospatial library of functions that can be used to create a spatial polygon. We will use it to create a polygon around the DC mall area. This will be our zone of interest.
*/
/* TEXT Block End */


/* SQL Block Start */
-- A temporary table to show the envelope on the map
CREATE OR REPLACE TABLE envelope AS 
SELECT ST_MAKEENVELOPE(-77.05, 38.90, -77.0, 38.885) AS zone;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE A VIEW THAT RECORDS ALERTS
The materialized view below records an occurence where a vehicles location coincides with the boundary of the zone of interest in the last 5 minutes.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW geofence_alert
REFRESH EVERY 5 SECONDS AS 
SELECT * 
FROM vehicle_5, envelope 
WHERE STXY_CONTAINS(zone, x, y) AND
TIMEBOUNDARYDIFF('MINUTE', TIMESTAMP, NOW()) < 5;
/* SQL Block End */


/* TEXT Block Start */
/*
SETUP A STREAM OF ALERTS
A stream in Kinetica can be used to publish changes on a table to a target destination. This target could be a webhook or a Kafka topic.
GO TO WEBHOOK.SITE TO TRY THIS EXAMPLE ON YOUR OWN
The easiest way to test this code out is by using a webhook. You can generate one for free and observe requests coming in via the following website: https://webhook.site/.
Please visit
https://webhook.site/
to generate a webhook and paste it in the code below to create the stream. Once the stream is setup head back over to https://webhook.site/ to observe the requests coming in.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM vehicle_inzone
ON TABLE geofence_alert
REFRESH ON CHANGE
WITH OPTIONS 
(
    DESTINATION = 'PASTE THE WEHOOK URL HERE'
);
/* SQL Block End */

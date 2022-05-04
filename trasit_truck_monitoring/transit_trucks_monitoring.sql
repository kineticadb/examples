/* Workbook: Real time transit truck monitoring */
/* Workbook Description: Monitor the temperature of cold storage transit trucks in real time. */


/* Worksheet: 1. Data setup (DDL) */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
Cold transit truck monitoring system with Kinetica
Interrupted or incorrect temperature control during transit is the cause of over one-third of the world’s food spoilage. This represents billions of dollars in losses every year. Maintaining the correct temperature in transit is THE challenge in cold chain logistics.
The temperature inside a delivery truck can vary a lot based on the number of times it is opened for deliveries, the weather outside or due to malfunctioning equipment. It is therefore important to monitor the conditions inside the truck at all times so that any shift from ideal storage conditions can be immediately flagged and corrected.
A real time monitoring system for cold transit requires you to combine different streaming data sources that record things like GPS, pressure, temperature etc. But the challenge  is that this information is often coming from different sensors which record and send this information out at different points in time.  So combining them is not a straightforward task.
In this demo, we use Kinetica's ASOF join and materialized view capabilities to perform an inexact join between vehicle location data and metrics that is continuously updated as new data streams in.
So let's get started!
⚠️ WARNING
: Make sure to pause the Kafka stream ingest after you are done with the demo (see the cleanup sheet) so that your tables don't get too large.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Reduce the kafka batch size
The default batch size when ingesting data from kafka is 1000 records. While this is good for most purposes, we will reduce that to 10 for this demo. This is because we want to generate a smooth visualization for the location of the transit trucks.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Reducing the default batch size for kafka so that tracks appear smooth. Larger batch sizes will render as big jumps when visualizing tracks.
ALTER SYSTEM SET PROPERTIES ('kafka_batch_size' = '10');
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE SCHEMA AND TABLES
Kinetica uses schema's to organize tables. It is good practice to have a schema defined for each project. Tables that are created without an explicit schema assignment are placed in the default schema ki_home.
ABOUT THE TABLES
We will be working with two streaming data tables
with fake data
, one that records vehicle locations and another that records vehicle metrics like temperature and pressure. Both these tables are recording information for transit trucks. The trucks are identified by identifier columns (TRACKID for locations and ID for metrics).
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE SCHEMA IF NOT EXISTS transit_trucks;
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE transit_trucks.vehicle_locations
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
CREATE OR REPLACE TABLE transit_trucks.vehicle_metrics
(
    ID integer,
    "cycle" int,
    setting1 float,
    setting2 float,
    setting3 float,
    concentration float,
    flow_rate float,
    "compression" float,
    pressure float,
    volume float,
    mats float,
    dense float,
    volt float,
    cap float,
    stdev float,
    temp float,
    s12 float,
    s13 float,
    s14 float,
    s15 float,
    s16 float,
    s17 float,
    s18 float,
    s19 float,
    s20 float,
    s21 float,
    ttf int,
    ts timestamp
);
/* SQL Block End */


/* TEXT Block Start */
/*
REGISTER THE DATA SOURCES
Next we register the data sources from which we will be ingesting the data. We need to specify a separate data source for each Kafka topic.
It's usually best practice to specify credentials separately so that they can be reused for the same provider (in this case confluent).
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE CREDENTIAL transit_trucks.confluent_creds
TYPE = 'kafka'
WITH OPTIONS (
    'security.protocol' = 'SASL_SSL',
    'sasl.mechanism' = 'PLAIN',
    'sasl.username'='FKHU5OKQSM6J3FZY',
    'sasl.password'='BT0b0049Q016ncuMUD0Pt5bRPr6YZu9YNioEtGqfuaN1pPmwyPUVMytUWloqtt8o'
);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE transit_trucks.vehicle_metrics_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS (
    'kafka_topic_name' =  'vehicle_metrics',
    credential = 'transit_trucks.confluent_creds'
);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE transit_trucks.vehicle_locations_source
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS (
    'kafka_topic_name' =  'vehicle_locations',
    credential = 'transit_trucks.confluent_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA FROM THE DATA SOURCES
Now that the data sources are registered, we can start loading data from them into the tables that we defined earlier.
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD DATA INTO transit_trucks.vehicle_locations
FROM FILE PATH ''
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'transit_trucks.vehicle_locations_source',
    KAFKA_GROUP_ID = 'BH_90210',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed'

);
/* SQL Block End */


/* SQL Block Start */
LOAD DATA INTO transit_trucks.vehicle_metrics
FROM FILE PATH ''
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'transit_trucks.vehicle_metrics_source',
    KAFKA_GROUP_ID = 'BH_90210',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed'

);
/* SQL Block End */


/* Worksheet: 2. Data exploration */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
EXPLORE THE DATA
Workbench comes with built in tools (map block, data explorer and visualization tabs etc.) that make it easy to explore and understand your data.
Let's start by looking the number of observations in the vehicle locations data grouped by the trucks (identified by TRACKID).
✎

Note
: It may take a few minutes for the data to show up based on when it hits the Kafka topic on confluent.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT TRACKID, COUNT(*) 
FROM transit_trucks.vehicle_locations
GROUP BY TRACKID;
/* SQL Block End */


/* TEXT Block Start */
/*
A MAP SHOWING THE MOVEMENT OF TRUCKS
Kinetica provides geospatial object called tracks that represents the path an object takes across the map. A track is a combination of an id, timestamp and a point (lat and lon).  We can use this feature to represent moving objects on a map.
We have currently set the auto refresh option to 5 seconds. So the map will refresh every 5 seconds to show the movement of trucks over time as new data streams in from the kafka topics. You can use the configure modal to play around with the different options for the map block.
✎ Note
: The tracks interface on Kinetica (as of version 7.1.6.9)
requires
that column names in the table that is being used to render the tracks be the following TRACKID, TIMESTAMP, x, y. The tracks currently will not render correctly if the columns are not named as above. Future versions of Kinetica will relax these restrictions.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
EXPLORE THE VEHICLE METRICS DATA
Let's
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT ID as truck_id, COUNT(*) as count
FROM transit_trucks.vehicle_metrics
GROUP BY ID;
/* SQL Block End */


/* TEXT Block Start */
/*
VISUALIZE THE TEMPERATURE OVER TIME
Workbench also provides a series of charts that can be used to visualize the output from select statements. We can use that to quickly plot the output from a select statement. Here, we use it to visualize the temperature over time.
✎ Note:
The visualization will be sparse initially (most likely a single point) the first time you run the query below since because there isn't enough data to visualize. Try re-running the query in 30 mins to see more points.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT id, HOUR(ts) as ts_hour, max(temp) as max_temp
FROM transit_trucks.vehicle_metrics
GROUP BY id, HOUR(ts);
/* SQL Block End */


/* Worksheet: 3. Analytics */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
A SIMPLE JOIN DOES NOT WORK
The vehicle location and metrics data share an id column and timestamp. A simple inner join will try to match the records from both tables by id and timestamp. But this will not work. This is because the vehicle metrics are being recorded at a different timestamp than the vehicle locations. So joining them together will not yield as many hits because the timestamps don't align  (see animation below).
✎ Note
: Wait till both the tables have records to run the queries.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create a materialized view that joins the two tables using id and timestamps
CREATE OR REPLACE MATERIALIZED VIEW transit_trucks.vehicle_analytics
REFRESH EVERY 5 SECONDS
AS
SELECT vl.TRACKID AS vehicle_id, DATETIME(vm.ts) as DATETIME, vm.pressure
FROM 
transit_trucks.vehicle_locations vl 
INNER JOIN transit_trucks.vehicle_metrics vm ON vl.TRACKID = vm.id AND vl.TIMESTAMP = vm.ts;
/* SQL Block End */


/* SQL Block Start */
-- We don't get that many hits with this
SELECT COUNT(*) FROM transit_trucks.vehicle_analytics;
/* SQL Block End */


/* TEXT Block Start */
/*
ASOF JOINS
The solution to this problem is an ASOF join. An ASOF join performs inexact joins by establishing an interval within which to look for matches. So instead of looking for an exact match, we look for matches within a specified interval as shown in the illustration below
✎ Note
: The illustration below references a different set of tables than those in this demo. But the concept is the same.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE A MATERIALIZED VIEW THAT USES ASOF JOINS
The code below is similar to the query we wrote above but the big difference is that we add an ASOF statement at the end which establishes a 10 second interval with (along with some arbitrary stats).
MATERIALIZED VIEWS KEEP EVERYTHING UPDATED
The great thing about using a materialized view here is that all of the calculations and the ASOF join are automatically updated as new data streams in to the input location and metrics tables. We don't have to do any additional data engineering
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW transit_trucks.realtime_vehicle_analytics
REFRESH EVERY 5 SECONDS 
AS 
SELECT
/* KI_HINT_PROJECT_MATERIALIZED_VIEW */
vl.TRACKID,
DATETIME(vm.ts) as TIMESTAMP,
vl.x,
vl.y,
(vm.pressure/100) as pressure,
(vm."compression"/20) as avg_compression,
(vm.temp/1000) as temperature
FROM transit_trucks.vehicle_locations vl 
INNER JOIN
transit_trucks.vehicle_metrics vm
ON vl.TRACKID = vm.id AND
ASOF(vl.TIMESTAMP, vm.ts, INTERVAL '0' SECONDS, INTERVAL '10' SECONDS, MIN);
/* SQL Block End */


/* TEXT Block Start */
/*
ASOF JOINS YIELD MORE MATCHES
Since we are using an ASOF join to establish a window within which to search for matches, we end up with more number of matching records.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT COUNT(*) 
FROM 
transit_trucks.realtime_vehicle_analytics;
/* SQL Block End */


/* TEXT Block Start */
/*
READY FOR SETTING UP THE MONITORING SYSTEM
The code for generating the materialized view is deceptively simple but with just that single query, Kinetica will now listen for changes in the underlying input tables and update the materialized view (i.e. the ASOF join) anytime there is new data.
Now we can setup downstream alerts and decisioning systems that are triggered whenever the temperature (or any other metric) crosses certain thresholds. We can also build extensive dashboards that build on the information from this view.
*/
/* TEXT Block End */


/* Worksheet: 4. Downstream monitoring systems */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
Now that we have a continuously updated ASOF Join view that combines location and metrics data we can go ahead and point downstream dashboards and alerting systems to the materialized view table to get real time information on the trucks that are not maintaining the correct conditions for cold transit.
SETTING UP AN ALERT FOR TEMPERATURE GREATER THAN 60
There are a few different ways to do it. We could set up a Kafka data sink that receives all new records from the portfolio alert table that we created in the previous sheet. We can use webhooks to setup alerts on applications like Slack etc.
For this demo, we recommend using the website: https://webhook.site/ to generate a webhook URL. Copy the webhook URL and paste it as the destination in the stream below. This will send alerts to that URL any time the temperature value is greater than 60 for a particular truck.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM alert_webhook
ON TABLE transit_trucks.realtime_vehicle_analytics
WHERE temperature > 60
WITH OPTIONS 
(
    DESTINATION = 'https://webhook.site/0bf1d616-7fb2-4ccf-9a94-a33287d9c09c' -- 'Paste Webhook URL'
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE A SLACK ALERT
The only change in the query below is that we use a webhook that is specifically for slack. You can find more information on how to set this up here: https://api.slack.com/
✎ Note
: Don't forget to update the destination url with your key if you would like to receive updates via slack
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM alert_slack_transit_truck
ON TABLE transit_trucks.realtime_vehicle_analytics
WHERE temperature > 60
WITH OPTIONS 
(
    DESTINATION = 'https://hooks.slack.com/services/<ENTER YOUR KEY>'
);
/* SQL Block End */


/* TEXT Block Start */
/*
Kafka sink
You can also send the alerts to a Kafka topic. Uncomment the code below and update the details for your Kafka cluster to point the alerts to a Kafka topic, which can then be used in downstream analytics or triggers.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE OR REPLACE DATA SINK transit_truck_alerts
-- LOCATION = '<kafka cluster address>'
-- WITH OPTIONS 
-- (
--     kafka_topic_name =  'topic name',
--     credential = 'your credentials'
-- );
/* SQL Block End */


/* SQL Block Start */
-- CREATE STREAM portfolio_alert_stream on 
-- TABLE fin_risk.portfolio_alert
-- WITH OPTIONS 
-- (
--     event = 'insert', 
--     datasink_name = 'transit_truck_alerts'
-- );
/* SQL Block End */


/* TEXT Block Start */
/*
SETUP A DASHBOARD APP WITH REVEAL OR A THIRD PARTY WEB APP
The Along with alerts we can also setup a realtime dashboard using either Kinetica's data visualization tool Reveal or a third party application like tableau. You can find more information
*/
/* TEXT Block End */


/* Worksheet: 4. Clean up sheet */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
CLEAN UP
1. Reset the Kafka ingest batch size back to the default setting.
2. Drop the schema and associated data
*/
/* TEXT Block End */


/* SQL Block Start */
-- Resetting the batch size back to default
ALTER SYSTEM SET PROPERTIES ('kafka_batch_size' = '1000');
/* SQL Block End */


/* TEXT Block Start */
/*
Drop the schema and all the tables inside it.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop the tables (we need to do this first because )
DROP TABLE IF EXISTS transit_trucks.vehicle_locations;
DROP TABLE IF EXISTS transit_trucks.vehicle_metrics;
/* SQL Block End */


/* SQL Block Start */
-- Drop the schema (and associated data sources)
DROP SCHEMA IF EXISTS transit_trucks CASCADE;
/* SQL Block End */

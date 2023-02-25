/* Workbook: Spatial Analytics */
/* Workbook Description: Bite sized use cases */


/* Worksheet: Data Setup */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCES
We will be using three different data sources for this example. Two Kafka topics and one small file loaded from AWS S3. Our first task is to register all of these data sources so that we can connect to them.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop any existing tables that subscribe to these data sources
DROP TABLE IF EXISTS vehicle_locations; 
DROP TABLE IF EXISTS dc_fences;
DROP TABLE IF EXISTS taxi_trips;

-- The AWS S3 bucket
CREATE OR REPLACE DATA SOURCE examples_data
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);

-- Credentials for Kafka cluster
CREATE OR REPLACE CREDENTIAL truck_creds
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
    credential = 'truck_creds'
);

-- Create the data source for taxi stream
CREATE OR REPLACE DATA SOURCE taxi_streaming_ds
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'qs_taxi',
    credential = 'qs_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
STREAM OF GPS COORDINATES OF 7 TRUCKS IN DC
The block of code below creates a table for recording the position of trucks in and around DC and connects to a kafka data source that is streaming GPS coordinates from these trucks.
*/
/* TEXT Block End */


/* SQL Block Start */
-- A table to store the position of trucks over time.
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

-- Create a view to represent the last hour of data
CREATE OR REPLACE MATERIALIZED VIEW recent_locations
REFRESH EVERY 5 SECONDS AS 
SELECT * 
FROM vehicle_locations 
WHERE TIMEBOUNDARYDIFF('HOUR', TIMESTAMP, NOW()) < 1;
/* SQL Block End */


/* TEXT Block Start */
/*
TABLE WITH FENCES
The table below is used to store a set of fences that outline major landmarks in Washington DC.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE dc_fences 
(
    fence_id int,
    wkt geometry,
    fence_label varchar(32)
);
/* SQL Block End */


/* SQL Block Start */
LOAD DATA INTO dc_fences
FROM FILE PATHS 'landmark_fences.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_data'
);
/* SQL Block End */


/* TEXT Block Start */
/*
NY TAXI
A stream of NY taxi trips. This is for the binning sheet.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the data source. Each kafka topic is created as a separate data source.
LOAD DATA INTO taxi_trips
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'taxi_streaming_ds',
    SUBSCRIBE = 'TRUE',
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes  
);
/* SQL Block End */


/* Worksheet: 📖 - Primer */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
This section is a primer on geospatial analytics. Feel free to skip it if you have already worked with the ST function library from PostGIS.
VIDEO PLAYLIST
The video below is the start of a playlist that introduces geospatial analysis with Kinetica. Go through to it to familiarize yourself with the fundamentals of spatial analytics.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
THE ST FUNCTION LIBRARY
The ST functions library contains a wide range of functions related to spatial geometry, data analysis, and spatial data management. This library can be used to create and manipulate spatial data, perform spatial calculations and queries, generate maps and visualizations, and much more.
Kinetica offers more than 150 different ST_ functions. These can be broadly classified into the 3 categories shown below (based on their purpose).
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
COMPUTE ATTRIBUTES
Let's calculate the areas of the fences around landmarks in Washington DC using ST_AREA().
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT 
    fence_label,
    ROUND(ST_AREA(wkt, 1)) as area 
FROM dc_fences;
/* SQL Block End */


/* TEXT Block Start */
/*
IDENTIFY SPATIAL RELATIONSHIPS
Let's see if there are any fences that overlap using the ST_INTERSECTS function.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT 
    a.fence_id, 
    a.fence_label,
    b.fence_label as overlap,
    a.wkt
FROM dc_fences AS a, dc_fences AS b
WHERE ST_INTERSECTS(a.wkt, b.wkt) = 1 AND a.fence_label != b.fence_label;
/* SQL Block End */


/* TEXT Block Start */
/*
CONSTRUCT GEOMETRIES
Let's dissolve all the fences to create a single geometry. Notice how the boundaries between the overlapping fences (bottom left) have been dissolved in the map below.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TEMP TABLE dc_dissolved AS 
SELECT ST_DISSOLVE(wkt) as wkt
FROM dc_fences;
/* SQL Block End */


/* Worksheet: Spatial filtering */
/* Worksheet Description: Description for sheet 9 */


/* TEXT Block Start */
/*
SPATIAL FILTERING
A spatial filter is used to identify a subset of records from a table that meet some
criteria
based on a specific spatial query.
CRITERIA
Find fences that have a truck within 200 meters from them.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE fence_filter AS
SELECT wkt
FROM dc_fences 
WHERE ST_AREA(wkt, 1) > 500000;
/* SQL Block End */


/* Worksheet: Spatial Joins */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
WHAT IS A SPATIAL JOIN?
Spatial joins combine two different tables using a spatial relationship. They are used to answer questions such as “which areas overlap”, “where do the boundaries occur”, and “what is the area covered by a certain feature”. Spatial joins are typically computationally expensive to perform especially on larger data. But not so in Kinetica.
A SPATIAL JOIN
In the code below, we use a join to identify records where a truck is within 200 meters of a particular fence.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW vehicle_fence_join 
REFRESH ON CHANGE AS
SELECT 
    TRACKID, 
    x,
    y,
    DECIMAL(STXY_DISTANCE(x, y, wkt, 1)) as distance,
    fence_label,
    wkt
FROM recent_locations
INNER JOIN dc_fences 
    ON 
    STXY_DWITHIN(x, y, wkt, 200, 1) = 1;
/* SQL Block End */


/* TEXT Block Start */
/*
MAP SHOWING THE FENCES THAT HAD A RECENT TRUCK LOCATION (MARKED IN BLUE) WITHIN 200 METERS
*/
/* TEXT Block End */


/* Worksheet: Geofencing */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
WHAT IS GEOFENCING?
Geofencing is a location-based service in which a software application uses GPS, RFID, Wi-Fi or cellular data to trigger a pre-programmed action when a mobile device or RFID tag enters or exits a virtual boundary set up around a geographical location. Geofencing can be used for various purposes, such as sending notifications to customers when they enter or leave an area, providing targeted advertising based on location, and tracking employee time and attendance.
GEOFENCES
Take a look at the data set up sheet before proceeding. This will give you a good sense for what the query below is accomplishing. We have two tables of data. One is a stream that is recording live locations of different trucks Washington DC, while the second is a list of fences surrounding popular DC landmarks.
The query below identifies when a trucks GPS points falls within a fence. We only consider events that have occured in the last 5 minutes.
WHY IS THE MAP EMPTY?
First check if you have run the query below. The maps reference the data from the view that is created in that query. If the maps still stay empty it means that there are no geofencing events currently. But one will likely show up within a few minutes.
AUTOMAGICALLY UPDATE WITH A MATERIALIZED VIEW
The query below uses a materialized view that is set to refresh on change. So the results of this view are updated automatically whenever there is a new truck location added to Kinetica from the Kafka stream. A downstream application that relies on these geofencing events can simply point to this table in Kinetica and rely on our high speed key value lookups to deliver real time event alerts.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW fence_events 
REFRESH ON CHANGE AS 
SELECT 
    TRACKID, 
    wkt, 
    x, 
    y, 
    TIMESTAMP, 
    CONCAT(TRACKID, CONCAT(' is at ', fence_label)) as event_text 
FROM recent_locations, dc_fences
WHERE 
    STXY_CONTAINS(wkt, x, y) = 1 AND 
    TIMEBOUNDARYDIFF('MINUTE', TIMESTAMP, NOW()) < 5;
/* SQL Block End */


/* Worksheet: Entity tracking */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
WHAT ARE TRACKS?
Tracks are a
native
geospatial object in Kinetica (just like Points, Shapes and Labels). They represent objects in motion i.e. the path that an object takes over time.
HOW ARE TRACKS REPRESENTED?
Tracks use a combination of a track identifier, a timestamp value and X and Y coordinates to represent a path over time.
WHY ARE TRACKS USEFUL?
Pretty much any object that moves can be represented and studied using tracks. This has a wide range of application in almost all sectors of the economy including supply chain management, ride sharing, IoT devices.
WHATS THE BENEFIT OF STUDYING TRACKS IN KINETICA?
Kinetica come with a set of functions that can be used to compute attributes and to detect events such as geofencing and proximity to other tracks.
Apart from all the performance benefits, Kinetica's native track representation performs a key function, which is
track interpolation
, which allows us to infer events such as geofencing and proximity more accurately.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
TRACK ATTRIBUTES
Let's calculate the length and duration each of the truck tracks.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Compute the length and duration of tracks
CREATE OR REPLACE MATERIALIZED VIEW track_summary
REFRESH EVERY 1 MINUTE AS 
SELECT 
    TRACKID,
    ROUND(ST_TRACKLENGTH(Y, X,TIMESTAMP, 1) / 1000) AS track_length_km, 
    ROUND(ST_TRACKDURATION(MINUTE,TIMESTAMP)) as duration_mins
FROM recent_locations 
GROUP BY TRACKID;


SELECT * FROM track_summary;
/* SQL Block End */


/* TEXT Block Start */
/*
TRACK INTERSECTION
Let's identify if any of the trucks have intersected with the DC landmark fences.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW fence_trucks
REFRESH EVERY 5 SECONDS AS
SELECT *
FROM TABLE
(
    ST_TRACKINTERSECTS
    (
        TRACK_TABLE => INPUT_TABLE
        (
            SELECT * 
            FROM recent_locations
            WHERE TIMEBOUNDARYDIFF('MINUTE', TIMESTAMP, NOW()) < 5
        ),
        TRACK_ID_COLUMN => 'TRACKID',
        TRACK_X_COLUMN => 'x',
        TRACK_Y_COLUMN => 'y',
        TRACK_ORDER_COLUMN => 'TIMESTAMP',
        GEOFENCE_TABLE => INPUT_TABLE(dc_fences),
        GEOFENCE_ID_COLUMN => 'fence_id',
        GEOFENCE_WKT_COLUMN => 'wkt'
    )
);

SELECT * FROM fence_trucks;
/* SQL Block End */


/* TEXT Block Start */
/*
TRACK PROXIMITY
Let's detect if two different trucks came within 200 meters of each other within a 1 minute window.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Identify tracks that came within 200 meters of each other within a 1 minute window
CREATE OR REPLACE MATERIALIZED VIEW proximate_trucks 
REFRESH EVERY 1 MINUTE AS 
SELECT * FROM TABLE 
(
    ST_TRACK_DWITHIN
    (
        TRACK_TABLE => INPUT_TABLE(recent_locations),
        TRACK_ID_COLUMN => 'TRACKID',
        TRACK_X_COLUMN =>  'x',
        TRACK_Y_COLUMN =>  'y',
        TRACK_ORDER_COLUMN =>  'TIMESTAMP',
        SEARCH_TABLE => INPUT_TABLE(recent_locations),
        SEARCH_ID_COLUMN =>  'TRACKID',
        SEARCH_X_COLUMN =>  'x',
        SEARCH_Y_COLUMN =>  'y',
        SEARCH_ORDER_COLUMN =>  'TIMESTAMP',
            SEARCH_XY_DISTANCE => '200',
            SPATIAL_SOLUTION_TYPE => 1,
            SEARCH_TIME_DISTANCE => '1m'
    )
)
WHERE TRACK_TABLE_TRACKID <> SEARCH_TABLE_TRACKID;

SELECT * FROM proximate_trucks;
/* SQL Block End */


/* Worksheet: Binning */
/* Worksheet Description: Description for sheet 8 */


/* TEXT Block Start */
/*
BIN TAXI TRIPS IN NY TO FIND HOTSPOTS
Spatial binning is a technique used in data analysis to group geographically-referenced data into user-defined bins or areas. The technique is used to reduce the resolution of a dataset, making it easier to visualize and analyze large datasets. This can be done by dividing the area into equal-sized rectangular grids, circles, polygons, or hexagons. The resulting bins are then used for statistical analysis such as calculating the frequency of events or measuring average values.
Kinetica offers two ways to generate grids - ST_HEXGRID or using H3 geohashing functions (based on Uber).
Let's use the latter to visualize hotspots for taxi pickups in New York. The steps are as follows.
1. Use STXY_H3() to generate the H3 index, which is a number that points to a specific h3 grid that contains a particular x and y point.
2. Use ST_GEOMFROMH3() to generate the corresponding geom for each index we generated in the previous step.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Calculate the h3 index for each pickup and dropoff point
CREATE OR REPLACE MATERIALIZED VIEW nytaxi_h3_index
REFRESH ON CHANGE AS 
SELECT 
    pickup_latitude,
    pickup_longitude,
    STXY_H3(pickup_longitude, pickup_latitude, 9) AS h3_index_pickup,
    STXY_H3(dropoff_longitude, dropoff_latitude, 9) AS h3_index_dropff
FROM taxi_trips;
/* SQL Block End */


/* SQL Block Start */
-- Create the grid geom and aggregate pickups within each
CREATE OR REPLACE MATERIALIZED VIEW nytaxi_binned
REFRESH ON CHANGE AS 
SELECT 
    h3_index_pickup,
    ST_GEOMFROMH3(h3_index_pickup) AS h3_cell,
    COUNT(*) AS total_pickups
FROM nytaxi_h3_index 
GROUP BY h3_index_pickup;
/* SQL Block End */


/* TEXT Block Start */
/*
The map below shows the total pickups aggregated within each bin in NY. Both the queries above are based on a stream of taxi rides coming from Kafka, and they are set to refresh with new data. This means that map below (which is set to refresh every few seconds) will also update to show the real time information on pickups across NYC.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
TASKS FOR YOU TO EXPLORE
Clone this workbook to create an editable version of this example and try these out on your own.
1. Mirror the same for dropoffs.
2. Who pays more on average? Compare average taxi fares across different parts of NY
3. Who tips more? Compare tipping across different parts of NY
4. Who shares rides more? Compare average passenger counts across different parts of NY
*/
/* TEXT Block End */


/* Worksheet: Routing with Graphs */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
DEDICATED GRAPH LIBRARY
Kinetica offers an extensive library of Graph functions that can be used to create, query, solve and match graphs using tons of prebuilt solvers and identifier combinations.

GRAPH + GEO  👨‍❤️‍💋‍👨
Routing is a key area of spatial analytics. Kinetica's can represent road networks as graphs against which we can issue powerful pre-built solvers and match algorithms. This makes it really easy to solve spatial problems with a routing flavor.
And what's more, Graphs in Kinetica are fully compatible with a relational data model, so you can integrate graph analytics with your existing analytical data pipelines without any friction.

TRY THE SHORTEST PATH WORKBOOK
We have a separate workbook that goes into the basics of using graphs in Kinetica. Try that out next!
*/
/* TEXT Block End */

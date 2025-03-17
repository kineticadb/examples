/* Workbook: Quick Start Guide */
/* Workbook Description: Get started with Kinetica. */


/* Worksheet: START HERE */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
🚀 WHAT IS KINETICA
Kinetica is a database, purpose built for real-time analytics at scale. It leverages vectorized memory-first architecture with kernels that have been custom built for over a decade to deliver blistering performance at scale on significantly less infrastructure than traditional data warehouses. Using a highly-distributed, lockless design, Kinetica enables simultaneous ingestion and analysis with integrated geospatial, graph, SQL, and AI/ML capabilities. With out of the box connectors for ingest and egress, native language bindings and a rich API ecosystem, developers can leverage the tools that they are comfortable and familiar with to build and deploy advanced analytical applications.
tl;dr;
We are a really fast, easy to use database for real-time analytics on massive amounts of streaming data. You can use us for many things but we excel at enabling decisioning systems that require insights in seconds rather than minutes or hours.
QUICKSTART WORKBOOK
This workbook is an introduction to loading data into Kinetica, performing analytics and triggering alerts in real time.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
HOW TO USE WORKBOOKS
Workbooks are organized into worksheets. Worksheets are handy for organizing your work by separating the different sections of your analysis. Each worksheet contains blocks of code, text and media content. You can either execute all the code in a sheet by clicking on the "Run All" button or by running each individual block on it own.
RUN WORKSHEETS SEQUENTIALLY
All example workbooks use worksheets to sequentially order the code. This means that some of the code in later worksheets will rely on tables or views that may have been created in previous worksheets.
CREATE YOUR WORKBOOK
Use the Copy and Edit button on the top right to create a local copy of this workbook to work through the exercises. You can rename the workbook and edit it once copied. Your workbook can be found in the Expore section on the top. Select it now to continue this workbook.
*/
/* TEXT Block End */


/* Worksheet: 1. Load the data */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
LOAD DATA INTO KINETICA
Kinetica can load data from 100s of data sources using native connectors (Azure, GCS, HDFS, S3, Kafka) or JDBC. Kinetica has partnered with CData - a data connectivity platform that provides and maintains JDBC drivers for 100s of databases and applications. You can use these drivers for free to connect to popular databases like PostGres and applications like Salesforce and Google Drive.
Try out our data ingest guide for a full introduction to loading data into Kinetica: https://docs.kinetica.com/latest/load_data/concepts/
✌🏽2 STEPS TO CONNECT
For most cases, loading data into Kinetica involves just two queries.
1.
Create the Data Source
: This query establishes a connection with a data source using the specified location, credentials and any other additional parameters.
2.
Load Data
: This query loads data from a particular data source into Kinetica
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
REGISTER A STREAMING DATA SOURCE
This stream contains synthetic taxi pickups and drop-offs from a Kafka queue (up to the past hour). The ability to ingest streaming data and build always-on complex analytical pipelines on top of them is one of Kinetica's many differentiating features.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Register a streaming kafka data source
DROP TABLE IF EXISTS taxi_data_streaming;

-- Create the credentials for connecting to the Kafka Cluster. This step is optional since credentials can be specified when creating a data source.
CREATE OR REPLACE CREDENTIAL qs_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'QZN62QB2RBTLW74L',
   'sasl.password' = 'iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- Create the data source. Each kafka topic is created as a separate data source.
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
REGISTER AN S3 BUCKET AS A DATA SOURCE
For this guide, we'll use several files with historical geospatial data in them. The nyct2010.csv file provides geospatial boundaries for neighborhoods in New York. The taxi_data_historical.parquet file provides a list of taxi pickups and dropoffs in New York.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Register an S3 bucket that contains historical data
CREATE OR REPLACE DATA SOURCE quickstart
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA INTO TABLES
Kinetica has a robust type inferencing system that allows you to load data into a table without defining it.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Load the streaming data into Kinetica
LOAD DATA INTO taxi_data_streaming
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'taxi_streaming_ds',
    SUBSCRIBE = 'TRUE',
    ERROR_HANDLING = 'permissive',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS nyct2020;

-- Load the NYC neighborhood map into Kinetica
LOAD DATA INTO nyct2020 
FROM FILE PATHS 'quickstart/nyct2020.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS taxi_data_historical;

-- Load the historical trip data into Kinetica
LOAD DATA INTO taxi_data_historical
FROM FILE PATHS 'taxi_data.parquet'
FORMAT PARQUET
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
/* SQL Block End */


/* TEXT Block Start */
/*
The type inferencing system is pretty conservative in how it infers a specific type. In some cases, it might be necessary to tweak the DDL based on the type of data. For instance, both the vendor id and payment type columns have a max of either 4 or 16 characters. But the types are infered as unrestricted strings, which take more disk space to store than strings with a predefined length. We can update this using the ALTER TABLE command.
*/
/* TEXT Block End */


/* SQL Block Start */
ALTER TABLE taxi_data_historical
ALTER COLUMN vendor_id varchar(4);

ALTER TABLE taxi_data_historical
ALTER COLUMN payment_type varchar(16);
/* SQL Block End */


/* Worksheet: 2. Explore the data */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
THE DATA
Typically, the first thing we want to do after loading data is to inspect the table. You can use either a SELECT statement or use the preview option on the context menu when you click on a data object.
To preview using the UI: Go to the Data tab, the tables that were created in the previous worksheet are placed in your default schema (either ki_home or your username if you are using our SaaS version), click on them to bring up the context menu. The preview option will show the table while the WMS preview option (availabe for tables with Geospatial data) will show an option to configure a map. All the data is typically pre-filled for the map so you can click update to bring up a visual representation of the data as well.
We will use three tables in this workbook
1. nyct2010: This table contains geospatial boundaries of neighborhoods in New York City (NYC) along with additional metadata about each of them.
2. taxi_data_historical: This is historical information on the taxi trips in NYC. This includes information on pickup and dropoff points, trip time, fare etc.
3. taxi_data_streaming: This contains the same schema as the historical data but instead contains (synthetic) information on taxi trips that are happening right now in NYC. New trips are added to the table as they occur.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
SUMMARY STATISTICS
Calculating summary statistics is one of the first tasks when exploring a new dataset. The following query finds the shortest, average, and longest trip lengths for each vendor using the historical data.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    NVL(vendor_id, '<ALL VENDORS>') AS Vendor_Name,
    DECIMAL(MIN(trip_distance)) AS Shortest_Trip,
    DECIMAL(AVG(trip_distance)) AS Average_Trip,
    DECIMAL(MAX(trip_distance)) AS Longest_Trip,
    COUNT(*) AS Total_Trips
FROM taxi_data_historical
GROUP BY vendor_id;
/* SQL Block End */


/* TEXT Block Start */
/*
VISUALIZE DATA
It is always useful to get a sense of the quality of the data and the type of analytical questions that might be interesting to answer before diver deeper into analyzing it.
Workbooks offer a few different ways to visualize your data. These include map blocks for geospatial data and built in chart types for non-geospatial data.
MAP BLOCK
The map block visualizes the stream of taxi drop-offs. It is set to refresh periodically so that we can see new drop-offs as they show up.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
TASK
✍︎ Try configuring a map block below that uses the nyct2010 data. Use the + button on the top right of this block to add map a block below.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
RELATIONSHIP BETWEEN TRIP DISTANCE AND TOTAL FARE
Workbench offers several built in chart types (Bar, LIne, Pie and Scatter) that can be used to get a quick sense of non-geospatial data.  These are available only when we use a Select statement on workbench.
▶︎ Run the query below to see a scatter plot to see the relationship between total fare and trip distance.
TASK
✍︎ Try configuring a bar chart of your own for the summary statistics query that show the vendors on the the x axis and total trips on the y axis.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT * FROM taxi_data_historical;
/* SQL Block End */


/* Worksheet: 3. Location Analytics */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
GEOSPATIAL ANALYTICS WITH KINETICA
Kinetica was designed from the ground up for analysis and visualization of massive geospatial datasets. It natively supports points, shapes as WKT, tracks, and labels. There are over 130 geospatial functions that are available through SQL.
In this sheet we will run through a few queries that show how to to use geospatial queries in Kinetica.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Q1: What were the 10 most frequent destination neighborhoods for JFK pickups, and on average, what did it cost to go there?
The taxi trips data does not contain information about the neighborhood where a pickup or dropoff happened. To find the answer to this question, we will need to perform a geo join of the trips data with the neighborhood map (nyct2010) using the STXY_INTERSECTS function. We can then group the data by the  neighborhood name to determine the total number of trips and average fare for a trip from JFK to that neighborhood.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT TOP 10
    n_dropoff.NTAName AS Neighborhood,
    COUNT(*) AS Total_Trips,
    DECIMAL(AVG(fare_amount)) AS Average_Fare
FROM
    taxi_data_historical t
    JOIN nyct2020 n_pickup
        ON STXY_Intersects(t.pickup_longitude, t.pickup_latitude, n_pickup.geom) = 1
        AND n_pickup.NTAName = 'John F. Kennedy International Airport'
    JOIN nyct2020 n_dropoff
        ON STXY_Intersects(t.dropoff_longitude, t.dropoff_latitude, n_dropoff.geom) = 1
GROUP BY Neighborhood
ORDER BY Total_Trips DESC;
/* SQL Block End */


/* TEXT Block Start */
/*
Q2: For neighborhoods with more than 500 pickups, how many had more than half of their pickups at night and by what taxi vendor?
You can use neighborhood boundary data and pickup time to calculate in which NTA vendors were picking up passengers at night and display the results in a pivot table containing columns of percentages for all vendors and each individual vendor.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    NTANAme AS "Neighborhood",
    all_npp AS "All",
    cmt_npp AS "CMT", nyc_npp AS "NYC", vts_npp AS "VTS", ycab_npp AS "YCAB"
FROM
(
    SELECT
        NTAName,
        IF (GROUPING(vendor_id) = 1, CAST ('ALL' as varchar(4)), vendor_id) AS vendor_name,
        COUNT(*) AS total_pickups,
        DECIMAL(SUM(IF(HOUR(pickup_datetime) BETWEEN 5 AND 19, 0, 1))) / COUNT(*) * 100 AS night_pickup_percentage
    FROM
        taxi_data_historical t
        JOIN nyct2020 n
            ON STXY_Intersects(t.pickup_longitude, t.pickup_latitude, n.geom) = 1
    WHERE pickup_datetime < '2019-01-01'
    GROUP BY
        NTAName,
        ROLLUP(vendor_id)
)
PIVOT
(
    MAX(total_pickups) AS tp,
    MAX(night_pickup_percentage) AS npp
    FOR vendor_name IN ('ALL', 'CMT', 'NYC', 'VTS', 'YCAB')
)
WHERE all_tp > 500 AND all_npp > 50
ORDER BY all_npp DESC;
/* SQL Block End */


/* TEXT Block Start */
/*
Q3: How many pickups per hour were there at JFK International Airport?
Using the STXY_Intersects function to determine which pickup points were located in the JFK International Airport neighborhood boundary, it’s simple to calculate the number of pickups per hour there were at JFK for all cab types. We've added a bar chart to visualize the results.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    RPAD(LPAD(CHAR2(HOUR(t.pickup_datetime)), 2, '0'), 5, ':00') AS "Pickup_Hour",
    COUNT(*) AS "Total_Pickups"
FROM
    taxi_data_historical t
    JOIN nyct2020 n
    ON STXY_Intersects(t.pickup_longitude, t.pickup_latitude, n.geom) = 1
WHERE
    NTAName = 'John F. Kennedy International Airport' AND
    pickup_datetime < '2019-01-01'
GROUP BY
    HOUR(t.pickup_datetime)
ORDER BY
    1;
/* SQL Block End */


/* Worksheet: 5. Real time alerting */
/* Worksheet Description: Description for sheet 8 */


/* TEXT Block Start */
/*
GENERATE REAL-TIME INSIGHTS WITH KINETICA
Kinetica's vectorized engine can run complex queries really fast. We can use this speed to build materialized views that can be set to refresh so that we have an always-on system that can trigger insights and alerts whenever there is an event of interest.
Let's see this in action below.
THE PROBLEM
Say you own a restaurant close to Union Square in NYC. You are interested in marketing your menu and restaurant to people who are getting dropped off via cabs near your restaurant. But right now, you have no way of finding out when someone is dropped off next your restaurant (unless you happen to see them as they are being dropped off).
THE SOLUTION
We can use Kinetica to set up an alert whenever a particular drop off location is within a certain distance of your store. When such as an event is detected, Kinetica will automatically send out an alert that includes information on the drop off point to your phone. You or one of your marketing agents can use this information to immediately step out and chat with the potential customer.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
MATERIALIZED VIEWS
Materialized views can be kept up to date using 4 modes - manual, on change, on query, or periodic. Here we will use the periodic option to select all the drop offs that are within 200 meters of your restaurant in the last 10 minutes. This query is refreshed every 5 seconds, so you will recieve an alert if there was a new dropoff in the last 5 seconds.
✎ NOTE
: There is an element of chance for the query below, since it is not necessary that there are any dropoffs happening around the store at a given point time. So you might not see new dropoffs appear immediately.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW store_front_dropoffs
REFRESH EVERY 5 SECONDS
AS
SELECT 
    DATETIME(dropoff_datetime) AS dropoff_datetime,
    dropoff_latitude, 
    dropoff_longitude, 
    vendor_id
FROM taxi_data_streaming
WHERE GEODIST(-73.992975, 40.736562, dropoff_longitude, dropoff_latitude) < 200 AND 
TIMEBOUNDARYDIFF('MINUTE', dropoff_datetime, NOW()) < 10
;
/* SQL Block End */


/* TEXT Block Start */
/*
The map below shows the dropoffs that are within 200 meters of the store in the last 10 minutes. It is set to update every 5 seconds, so new dropoffs will automatically show up whenever they satisfy the criteria.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
SETTING UP AN ALERT
Broadly speaking there are two ways to setup an alert using Kinetica. You could either push alerts via a webhook or your could stream them to a data sink (like Apache Kafka). For this example we will use a webhook.
SEE EVENTS BEING STREAMED IN REAL TIME
For this illustration, we will use the latter to send records to a pipedream webhook and then hook that up to the following google spreadsheet:
https://bit.ly/3IWFLQA
Copy the link above and paste in your browsers address bar to see taxi dropoff events within 200 meters of the store being detected in real time by Kinetica.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM dropoff_alert_webhook
ON TABLE store_front_dropoffs
REFRESH ON CHANGE
WITH OPTIONS 
(
    DESTINATION = 'https://eo8ebtcs7m354db.m.pipedream.net' 
);
/* SQL Block End */


/* Worksheet: 6. Other capabilities */
/* Worksheet Description: Description for sheet 8 */


/* TEXT Block Start */
/*
So far we have just scratched the surface with regard to Kinetica's analytical capabilities. The topics listed below are some of the other capabilities that come with Kinetica.
GRAPH ANALYTICS
Kinetica provides a generic and extensible library of graph functions that can be used to create, query, and solve graph network problems. These have applicatoins in areas such as transportation, utility, social, and geospatial. You can learn more about our graph capabilities here: https://docs.kinetica.com/7.2/graph_solver/network_graph_solver/#solvers
TIME ANALYTICS
Kinetica has several functions that can be used with time series data. These include window operations, ASOF joins and date and time manipulation functions.
MACHINE LEARNING
Kinetica can be used to deploy analytical pipelines that include containerized ML models that take inputs from Kinetica tables and output back to tables in Kinetica.
DASHBOARDS USING REVEAL
Kinetica also offers a dashboarding tool called Reveal (see below) that is really useful for exploring your data. However, Reveal is not available on the free SaaS and developer edition of Kinetica.
*/
/* TEXT Block End */


/* Worksheet: Chat GPT */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
START A CONVERSATION WITH YOUR DATA
Kinetica's GPT integration allows you to write analytical questions in English to generate the corresponding SQL query. Your results depend on the type of prompts and the context that you provide GPT.  Here are a few sample prompts (see expected results below) to get you started. Paste these into the chat input (without --) above and click send. The query will be added below for you to execute ▶️. You will need to create a copy of this workbook to edit the queries (the button next to Share on the top right). Once you are ready, try out a few prompts of your own. Also play around with the context (using the configure button) to see how that alters the resutls.
-- How many trips did each taxi vendor make to JFK airport?
-- Which were the top 5 origin neighborhoods for trips to JFK airport?
-- Use HOUR() and then summarize to find the total number of people who were dropped off at JFK for 1:00, 2:00, 3:00 and so on till 23:00
-- Which neighborhoods did people travel between the most in taxies? Don't include trips within the same neighborhood.
-- On average which neighborhoods tip taxi drivers the most in NYC? calculate tips as a percentage of the total fare amount.
🧪 Note
: This is an experimental feature. While chatGPT will often return the correct query the quality of the output depends on the prompt and context you provide. We have preconfigured the context so that it has information about the tables used in this workbook but you might have to refine the prompt and/or the output query occasionally to get the results you expect.
*/
/* TEXT Block End */


/* SQL Block Start */
-- EXPECTED RESULT FOR: How many trips did each taxi vendor make to JFK airport?
SELECT "vendor_id", COUNT(*) AS num_trips
FROM "taxi_data_historical"
WHERE ST_CONTAINS(
    (SELECT "geom" FROM "nyct2020" WHERE "NTAName" = 'John F. Kennedy International Airport'),
    ST_MAKEPOINT("dropoff_longitude", "dropoff_latitude")
)
GROUP BY "vendor_id";
/* SQL Block End */


/* SQL Block Start */
-- EXPECTED RESULT FOR: Which were the top 5 origin neighborhoods for trips to JFK airport?
SELECT 
    nta."NTAName" AS origin_neighborhood, 
    COUNT(*) AS trip_count 
FROM 
    "taxi_data_historical" AS taxi 
    JOIN "nyct2020" AS nta ON ST_CONTAINS(nta."geom", ST_MAKEPOINT(taxi."pickup_longitude", taxi."pickup_latitude")) 
WHERE 
    ST_CONTAINS((SELECT "geom" FROM "nyct2020" WHERE "NTAName" = 'John F. Kennedy International Airport'), ST_MAKEPOINT(taxi."dropoff_longitude", taxi."dropoff_latitude")) 
GROUP BY 
    origin_neighborhood 
ORDER BY 
    trip_count DESC 
LIMIT 5;
/* SQL Block End */


/* SQL Block Start */
-- EXPECTED RESULT FOR: Use HOUR() and then summarize to find the total number of people who were dropped off at JFK for 1:00, 2:00, 3:00 and so on till 24:00
SELECT HOUR(dropoff_datetime) AS hour, SUM(passenger_count) AS total_passengers
FROM taxi_data_historical
WHERE ST_CONTAINS((SELECT geom FROM nyct2020 WHERE NTAName = 'Jamaica'), ST_MAKEPOINT(dropoff_longitude, dropoff_latitude))
GROUP BY hour
ORDER BY hour;
/* SQL Block End */


/* SQL Block Start */
-- EXPECTED RESULT FOR: Which neighborhoods did people travel between the most in taxies? Don't include trips within the same neighborhood.
SELECT 
    n1."NTAName" AS starting_neighborhood, 
    n2."NTAName" AS ending_neighborhood, 
    COUNT(*) AS trip_count
FROM 
    "taxi_data_historical" t
    JOIN "nyct2020" n1 ON ST_CONTAINS(n1."geom", ST_MAKEPOINT(t."pickup_longitude", t."pickup_latitude"))
    JOIN "nyct2020" n2 ON ST_CONTAINS(n2."geom", ST_MAKEPOINT(t."dropoff_longitude", t."dropoff_latitude"))
WHERE 
    n1."NTAName" <> n2."NTAName"
GROUP BY 
    n1."NTAName", n2."NTAName"
ORDER BY 
    trip_count DESC;
/* SQL Block End */


/* SQL Block Start */
-- EXPECTED RESULT FOR: On average which neighborhoods tip taxi drivers the most in NYC? calculate tips as a percentage of the total fare amount.
SELECT 
    n."NTAName" AS neighborhood, 
    AVG(t."tip_amount" / t."total_amount") * 100 AS avg_tip_percentage
FROM 
    "taxi_data_historical" t 
JOIN 
    "nyct2020" n 
ON 
    ST_CONTAINS(n."geom", ST_MAKEPOINT(t."dropoff_longitude", t."dropoff_latitude")) 
GROUP BY 
    neighborhood 
ORDER BY 
    avg_tip_percentage DESC;
/* SQL Block End */

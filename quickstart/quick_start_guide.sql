/* Workbook: Quick Start Guide KDOC-1843 */
/* Workbook Description: Get started with Kinetica. */


/* Worksheet: Sheet 1 */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
Note
This workbook uses your user’s default schema for all blocks. If your default schema is shared with other users, the blocks will overwrite previously created data objects. It is a best practice to scope your user’s default schema to a unique namespace before running this workbook.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Stream Data into Kinetica
Start a stream of synthetic taxi pickups and drop-offs from a Kafka queue to show Kinetica's ability to build materialized views on top of it.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS taxi_data_streaming;

CREATE OR REPLACE DATA SOURCE taxi_streaming_ds
LOCATION = 'KAFKA://quickstart.kinetica.com:9092'
WITH OPTIONS (KAFKA_TOPIC_NAME = 'nyctaxi');
/* SQL Block End */


/* SQL Block Start */
LOAD DATA INTO taxi_data_streaming 
FORMAT JSON
WITH OPTIONS (
    DATA SOURCE = 'taxi_streaming_ds',
    SUBSCRIBE = 'TRUE'
);
/* SQL Block End */


/* TEXT Block Start */
/*
Visualize Streaming Taxi Events
New data is shown on the map with every refresh.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Import Historical Data
For this guide, we'll use several files with geospatial data in them. The nyct2010.csv file provides geospatial boundaries for neighborhoods in New York. The taxi_data_historical.parquet file provides a list of taxi pickups and dropoffs in New York.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE quickstart
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'quickstartpublic',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS nyct2010;

LOAD DATA INTO nyct2010 
FROM FILE PATHS 'nyct2010.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS taxi_data_historical;

LOAD DATA INTO taxi_data_historical
FROM FILE PATHS 'taxi_data.parquet'
FORMAT PARQUET
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
/* SQL Block End */


/* SQL Block Start */
ALTER TABLE taxi_data_historical
ALTER COLUMN vendor_id varchar(4);

ALTER TABLE taxi_data_historical
ALTER COLUMN payment_type varchar(16);
/* SQL Block End */


/* TEXT Block Start */
/*
Query Historical Data with SQL
What are the shortest, average, and longest trip lengths for each vendor?
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    NVL(vendor_id, '<ALL VENDORS>') AS Vendor_Name,
    DECIMAL(MIN(trip_distance)) AS Shortest_Trip,
    DECIMAL(AVG(trip_distance)) AS Average_Trip,
    DECIMAL(MAX(trip_distance)) AS Longest_Trip,
    COUNT(*) AS Hist_Total_Trips
FROM taxi_data_historical
GROUP BY vendor_id;
/* SQL Block End */


/* TEXT Block Start */
/*
Query Streaming Data with SQL
Create a materialized view that blends historical and streaming data that refreshes every query
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW M1
REFRESH ON QUERY AS
SELECT
    Today_Vendor_Name as Vendor_Name,
    Today_Shortest_Trip,
    Today_Average_Trip,
    Today_Longest_Trip,
    Today_Total_Trips,
    Hist_Shortest_Trip,
    Hist_Average_Trip,
    Hist_Longest_Trip,
    Hist_Total_Trips
FROM
(
    SELECT
        NVL(vendor_id, '<ALL VENDORS>') AS Today_Vendor_Name,
        DECIMAL(MIN(trip_distance)) AS Today_Shortest_Trip,
        DECIMAL(AVG(trip_distance)) AS Today_Average_Trip,
        DECIMAL(MAX(trip_distance)) AS Today_Longest_Trip,
        COUNT(*) AS Today_Total_Trips
    FROM taxi_data_streaming
    GROUP BY vendor_id
) t1
INNER JOIN
(
    SELECT
        NVL(vendor_id, '<ALL VENDORS>') AS Hist_Vendor_Name,
        DECIMAL(MIN(trip_distance)) AS Hist_Shortest_Trip,
        DECIMAL(AVG(trip_distance)) AS Hist_Average_Trip,
        DECIMAL(MAX(trip_distance)) AS Hist_Longest_Trip,
        COUNT(*) AS Hist_Total_Trips
    FROM taxi_data_historical
    GROUP BY vendor_id
) t2
ON t2.Hist_Vendor_Name = t1.Today_Vendor_Name;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM M1;
/* SQL Block End */


/* TEXT Block Start */
/*
Location Analytics
Q1: What were the 10 most frequent destination neighborhoods for JFK pickups, and on average, what did it cost to go there?
Joining the NTA table and the taxi data using the STXY_Intersects function, you can group by neighborhood boundary to determine the total number of trips to the neighborhood and average fare for a trip from JFK to that neighborhood.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT TOP 10
    n_dropoff.NTAName AS "Neighborhood",
    COUNT(*) AS "Total_Trips",
    DECIMAL(AVG(fare_amount)) AS "Average_Fare"
FROM
    taxi_data_historical t
    JOIN nyct2010 n_pickup
        ON STXY_Intersects(t.pickup_longitude, t.pickup_latitude, n_pickup.geom) = 1
        AND n_pickup.NTAName = 'Airport'
    JOIN nyct2010 n_dropoff
        ON STXY_Intersects(t.dropoff_longitude, t.dropoff_latitude, n_dropoff.geom) = 1
WHERE pickup_datetime < '2019-01-01'
GROUP BY 1
ORDER BY 2 DESC;
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
        DECIMAL(SUM(IF(HOUR(pickup_datetime) BETWEEN 5 AND 19, 0, 1)))
            / COUNT(*) * 100 AS night_pickup_percentage
    FROM
        taxi_data_historical t
        JOIN nyct2010 n
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
Using the STXY_Intersects function to determine which pickup points were located in the JFK International Airport neighborhood boundary, it’s simple to calculate the number of pickups per hour there were at JFK for all cab types.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    RPAD(LPAD(CHAR2(HOUR(t.pickup_datetime)), 2, '0'), 5, ':00') AS "Pickup_Hour",
    COUNT(*) AS "Total_Pickups"
FROM
    taxi_data_historical t
    JOIN nyct2010 n
    ON STXY_Intersects(t.pickup_longitude, t.pickup_latitude, n.geom) = 1
WHERE
    NTAName = 'Airport' AND
    pickup_datetime < '2019-01-01'
GROUP BY
    HOUR(t.pickup_datetime)
ORDER BY
    1;
/* SQL Block End */


/* TEXT Block Start */
/*
Visualization
Kinetica’s main visualization tools are Reveal and the Web Mapping Service (WMS). For our purposes, let's use the WMS feature.
Kinetica’s web map service renders geospatial images that are overlaid on map tools like Mapbox, OpenLayers, and Esri. Simply point your basemap provider to our /wms endpoint with your desired rendering parameters, and Kinetica will generate geospatial imagery on demand. Every pan and zoom will render a new image of your data, so you can visualize streaming updates in real time.
Q4: Given my storefront’s location, how can I calculate the number of drop offs that occurred within 150 meters?
Say you own a small business or restaurant in Chelsea that relies on nearby foot traffic for new customers. You can easily visualize the density of taxi drop offs nearby with the help of the GEODIST function.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE store_front_dropoffs AS
SELECT *
FROM taxi_data_historical
WHERE GEODIST(-74.00378, 40.743193, dropoff_longitude, dropoff_latitude) < 150;
/* SQL Block End */


/* TEXT Block Start */
/*
Load a Reveal Dashboard
Load the "NYC Taxi" Reveal dashboard from Kinetica's Github account and then navigate to https://<hostname>/reveal and log in to see the dashboard.
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD DASHBOARD "NYC Taxi"
FROM FILE PATH 'https://github.com/kineticadb/examples/raw/master/quickstart/nyctaxi.db';
/* SQL Block End */


/* TEXT Block Start */
/*
Pause Your Kafka Data Stream
(Or let it run to accumulate more data)
*/
/* TEXT Block End */


/* SQL Block Start */
ALTER TABLE taxi_data_streaming
PAUSE SUBSCRIPTION taxi_streaming_ds;
/* SQL Block End */

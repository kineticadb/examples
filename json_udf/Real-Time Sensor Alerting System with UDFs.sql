/* Workbook: Real-Time Sensor Alerting System with UDFs  */
/* Workbook Description:  */


/* Worksheet: Introduction */
/* Worksheet Description: This sheet outlines the table structure for storing sensor data and weather data.

 */


/* TEXT Block Start */
/*
Real-Time Sensor Alerting System for Smart Grid Monitoring
Smart grids rely on real-time sensor data and analytics to manage and monitor energy infrastructure. They measure key parameters such as voltage, current, temperature, and vibration across equipment like transformers and substations. However, these sensor readings can be influenced by external environmental conditions—such as heat, wind, and humidity—potentially leading to false alerts if not properly contextualized.
This SQL workbook demonstrates how to build a real-time anomaly detection system for industrial equipment using Kinetica’s streaming capabilities. The scenario simulates a network of IoT-enabled sensors deployed across a smart grid. These sensors report real-time metrics including temperature, humidity, voltage, and vibration. Sudden weather changes—such as high winds or drops in atmospheric pressure—can place additional stress on equipment and increase the risk of failure.
To mitigate such risks, this workbook shows how enriching device readings with external environmental metrics, we improve the accuracy of alerts and support smarter grid operations. Using Kinetica’s
User-Defined Functions (UDFs)
, materialized views, and ASOF (as-of) joins, the system enriches sensor streams with local weather metrics every five minutes. It then automatically detects anomalies—such as overheating, voltage spikes, or correlated vibration during high wind events, and pushes alerts to external systems for rapid response.
DATASETS USED:
1. IoT Sensor Data
: Simulated smart grid metrics such as temperature, humidity, voltage, and vibration collected from IoT-enabled field devices.
2. Weather Sensor Data
: Real-time environmental data fetched from the OpenWeather API every five minutes, including temperature, humidity, wind speed, and atmospheric pressure.
Together, these datasets enable a robust, data-driven monitoring system capable of distinguishing between equipment failure and weather-induced anomalies.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
This Workbook Is Divided Into Three Main Sections:
1. Data Setup
: You’ll simulate sensor readings in JSON format, extract and flatten this data into a structured table, and then pivot it for easier metric analysis. Simultaneously, you’ll use a Python UDF to fetch live weather data for mapped device locations. These two datasets—sensor and weather—are then prepped for real-time enrichment and anomaly detection.
2. Weather Enrichment and Anomaly Detection
: Using a Python UDF and ASOF joins, you’ll match each sensor reading with the most recent weather observation to generate enriched event records.
3. Real-Time Alerting:
Materialized views continuously monitor the enriched sensor records. When predefined thresholds are exceeded—such as high voltage during extreme heat—alerts are triggered and delivered in real time via a webhook stream or Slack integration.
How to Run the Demo
All necessary steps and instructions are provided within the workbook.
*/
/* TEXT Block End */


/* Worksheet: Sensor Data Setup (DDL) */
/* Worksheet Description:  */


/* TEXT Block Start */
/*
SETUP THE BASE TABLE
Below we will create a schema and a base table with a single column 'data' to store incoming raw sensor readings in JSON format. We will use UDFs to simulate raw sensor data into the base table.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP SCHEMA IF EXISTS json_extraction CASCADE;

CREATE SCHEMA IF NOT EXISTS json_extraction;

CREATE OR REPLACE TABLE json_extraction.base (
    data json
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE FLATTENED SENSOR DATA TABLE SCHEMA
The following SQL creates the json_extraction.sensor_flat table, which stores flattened sensor data extracted from nested JSON structures. Flattening the data simplifies querying and analysis by transforming complex, hierarchical sensor readings into a straightforward tabular format.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE json_extraction.sensor_data (
    device_id varchar(64) NOT NULL,
    last_updated datetime NOT NULL,
    scenario varchar(64, dict) NOT NULL,
    temperature real NOT NULL,
    humidity real NOT NULL,
    voltage real NOT NULL,
    vibration real NOT NULL
);
/* SQL Block End */


/* TEXT Block Start */
/*
Create Store Procedure to Flatten Nested Sensor Data
This stored procedure processes raw sensor data stored in the json_extraction.base table by flattening nested JSON structures and inserting the results into the sensor_flat table. It enables easier querying and analysis of individual sensor readings.
How it works:
1. Extract Top-Level Fields: Selects deviceId, lastUpdated, and the nested readings JSON array from the base table.
2. Explode Readings Array: Unnests the readings array so each reading becomes a separate row.
3. Structure Each Reading: Extracts scenario, status, and another nested metrics array from each reading.
4. Extract Metrics: Unnests the metrics array and extracts detailed fields like: ReadErrorMessage, ReadErrorType, ReadStatus, value (numeric sensor reading), type (sensor metric type, e.g., temperature)
5. Pivot the table: Pivot into a wide format—consolidating all metrics into a single row per device and timestamp.
This procedure automates transforming complex, nested JSON sensor data into a simple tabular format for downstream processing and analysis.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE PROCEDURE json_extraction.wrangle_sensor_data
BEGIN
  INSERT INTO json_extraction.sensor_data
  WITH readings_extracted AS (
    SELECT 
        json_value(data, '$.device_id') AS device_id,
        json_value(data, '$.last_updated') AS last_updated,
        json(json_query(data, '$.readings')) AS readings_array
    FROM json_extraction.base
  ),
  readings_exploded AS (
    SELECT 
        device_id, 
        last_updated, 
        reading.reading
    FROM readings_extracted, unnest_json_array(readings_array) reading
  ),
  readings_structured AS (
      SELECT
        device_id,
        last_updated,
        json_value(reading, '$.scenario') AS scenario,
        json_query(reading, '$.status') AS status,
        json(json_query(reading, '$.metrics')) AS metrics_array
    FROM readings_exploded
  ),
  readings_flat AS (
      SELECT 
        device_id,
        last_updated,
        scenario,
        json_value(status, '$.read_error_message') AS read_error_message,
        json_value(status, '$.read_error_type') AS read_error_type,
        json_value(status, '$.read_status') AS read_status,
        json_value(metric, '$.value') AS value,
        json_value(metric, '$.type') AS type
    FROM readings_structured, unnest_json_array(metrics_array) metric
  )
SELECT
    device_id,
    last_updated,
    scenario,
    temperature,
    humidity,
    voltage,
    vibration
FROM readings_flat
PIVOT (
    MAX(value) 
    FOR type IN ('temperature' AS temperature, 
                 'humidity' AS humidity, 
                 'voltage' AS voltage, 
                 'vibration' AS vibration)
);
END;
/* SQL Block End */


/* Worksheet: Simulating Sensor Data - UDF  */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
USER DEFINED FUNCTIONS (UDFs) in KINETICA
User-Defined Functions (UDFs) are custom functions created by users to perform operations that aren't covered by built-in functions within a database management system or programming environment. UDFs can serve to extend the functionality of SQL queries or to encapsulate complex logic into simpler function calls.
In this workbook, we use a Python UDF to fetch real-time weather metrics—such as temperature, humidity, wind speed, and pressure—based on the device’s location. This external context is then joined with IoT sensor readings to improve alert accuracy and reduce false positives caused by environmental conditions. By combining the speed and structure of SQL with the flexibility and intelligence of Python, Kinetica UDFs empower a truly adaptive real-time monitoring system.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
SETUP (MUST COMPLETE BEFORE RUNNING THE REST OF THE CODE)
Kinetica provides support for User-Defined Function (UDF) creation and management in SQL. Unlike conventional UDFs, Kinetica UDFs are external programs that can be managed via SQL and may be run in distributed fashion across the cluster. This workbook will cover these features.
1. 'enable_procs': To allow UDFs to be executed, we need to turn the 'enable_procs' option in the configuration parameters for the database. You can access these via GAdmin (http://localhost:8080/gadmin). The login credentials are the same as that for workbench (the tool you are in right now). In GAdmin go to Config -> Advanced. Search for enable_procs (CTRL/CMD + F) and set it to true. Click on Update. The will prompt you to restart the database. Choose this option. Once the database is back up, you can come back here to Workbench and complete the rest of the steps below.
2. Go to the Files tab (left side explorer) and make a directory on kifs called 'udf' for the purposes of this example.
3. Download the files 'simulate_sensor_data.py' and 'weather_data_enrich.py' containing the logic to simulate sensor and weather data located here [Github link].
3. Upload the file  'simulate_sensor_data.py' and 'weather_data_enrich.py' containing the logic to simulate sensor data above the 'udf' directory in KIFS.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Simulating and Inserting Sensor Data into the Base Table Using a Python UDF
First, we define a Python User-Defined Function (UDF) called 'simulate_sensor_data.py'  that simulates real-time sensor data and inserts it into the json_extraction.base table. The UDF generates synthetic readings resembling those from a physical device—such as temperature, humidity, voltage, and vibration—and streams them in JSON format.
To simulate continuous data ingestion, we schedule the UDF to run every 5 minutes over a 2-hour period.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Define Your Python UDF Environment
Create a Python environment to be used with your UDF. This ensures that your UDF runs with the required packages.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP FUNCTION simulate_sensor_data;
DROP FUNCTION weather_data_enrich;
/* SQL Block End */


/* SQL Block Start */
/*Altering your environment with SQL */
CREATE OR REPLACE FUNCTION ENVIRONMENT sensor_py_environment;

ALTER FUNCTION ENVIRONMENT sensor_py_environment INSTALL PYTHON PACKAGE 'requests';

-- Describe the environment to see the packages
DESCRIBE FUNCTION ENVIRONMENT sensor_py_environment;
/* SQL Block End */


/* TEXT Block Start */
/*
DECLARE YOUR PYTHON UDF FOR SENSOR DATA SIMULATION
This function simulates real time sensor readings into a UDF function to populate into the raw base json table, and registers it to the python environment created.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE FUNCTION simulate_sensor_data
RETURNS TABLE (
    data json
)
MODE = 'distributed'
RUN_COMMAND = 'python3'
RUN_COMMAND_ARGS = 'udfs/simulate_sensor_data.py'
FILE PATHS 'kifs://udfs/simulate_sensor_data.py'
WITH OPTIONS (SET_ENVIRONMENT = 'sensor_py_environment');
/* SQL Block End */


/* TEXT Block Start */
/*
SCHEDULE UDF EXECUTION VIA STORED PROCEDURE
The following stored procedure schedules the periodic insertion of simulated sensor data into the
json_extraction.base
table. It executes every 5 minutes and stops after 2 hours. Additionally, it calls another stored procedure,
wrangle_sensor_data
, to process the nested JSON structure into individual sensor readings for each timestamp.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE PROCEDURE json_extraction.sp_insert_sensor_data
BEGIN
    EXECUTE FUNCTION simulate_sensor_data (
        OUTPUT_TABLE_NAMES => OUTPUT_TABLES('json_extraction.base'),
        PARAMS =>  KV_PAIRS(device_id = 'sensor-4390')
    );
    EXECUTE PROCEDURE json_extraction.wrangle_sensor_data;    
END
EXECUTE FOR EVERY 5 MINUTES
STOP AFTER 120 MINUTES;

--To start the simulation
EXECUTE PROCEDURE json_extraction.sp_insert_sensor_data;
/* SQL Block End */


/* SQL Block Start */
--Query your raw json base table
SELECT * FROM json_extraction.base;
/* SQL Block End */


/* SQL Block Start */
--Query your flattened sensor table
SELECT * FROM json_extraction.sensor_data;
/* SQL Block End */


/* Worksheet: Simulating Weather Data - UDF */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
Enrich IoT Sensor Data with Weather Data Using Python UDF
To better understand sensor behavior in real-world conditions, we enrich the sensor data with local weather information. Environmental factors—such as high temperatures, humidity, or strong winds—can impact how sensors perform. For example, a sudden spike in a machine’s temperature sensor might not indicate a malfunction if it's a particularly hot and humid day.
By adding weather context, we can:
- Identify external causes for sensor anomalies (e.g., overheating due to high ambient temperatures).
- Improve anomaly detection by distinguishing between internal faults and external environmental changes.
- Gain deeper insights into how devices perform under different weather conditions.
We use a Python UDF to perform this enrichment. Here's how it works:
- The UDF queries the OpenWeather API using the sensor's device ID and location.
- It retrieves real-time weather metrics such as temperature, humidity, wind speed, and pressure.
- The fetched weather data is inserted into the weather_lookup table.
This UDF is designed to run periodically to simulate real-time enrichment, ensuring that each sensor reading is paired with up-to-date environmental data.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE WEATHER LOOK UP TABLE
This table stores real-time weather data for each device, based on location and timestamp. The data will later be joined with sensor data for enrichment and anomaly detection.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE json_extraction.weather_lookup (
    last_updated TIMESTAMP,
    latitude DOUBLE,
    longitude DOUBLE,
    weather_temp_c DOUBLE,
    weather_humidity INT,
    weather_pressure INT,
    wind_speed DOUBLE
);
/* SQL Block End */


/* TEXT Block Start */
/*
RETRIEVE API KEY FROM OPENWEATHER API
To retrieve an API key from OpenWeather, start by visiting
https://home.openweathermap.org
and creating an account. For this project, we will be using the Current Weather Data API, which provides real-time weather data based on geographic coordinates (latitude and longitude).
Once registered and signed in, navigate to your API key dashboard at
https://home.openweathermap.org/api_keys
. Create a new one by clicking “Create key,” assigning it a name, and saving it. This API key is required to authenticate requests to OpenWeather’s services, including current weather, forecasts, and historical data.
In our Python UDF, weather_data_enrich.py (uploaded to the /udfs directory), we dynamically insert the latitude, longitude, and API key to retrieve weather metrics such as temperature, humidity, wind speed, and pressure.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
LOAD WEATHER DATA USING UDF
Next, we register the weather_data_enrich.py script, which fetches real-time weather metrics from the OpenWeather API. This Python UDF retrieves weather data—such as temperature, humidity, wind speed, and pressure—based on each device's geolocation.
The enriched weather data is then used to enhance the sensor records, providing environmental context that can help explain anomalies or variations in sensor performance.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE FUNCTION weather_data_enrich
RETURNS TABLE (
    last_updated TIMESTAMP,
    latitude DOUBLE,
    longitude DOUBLE,
    weather_temp_c DOUBLE,
    weather_humidity INT,
    weather_pressure INT,
    wind_speed DOUBLE
)
MODE = 'distributed'
RUN_COMMAND = 'python3'
RUN_COMMAND_ARGS = 'udfs/weather_data_enrich.py'
FILE PATHS 'kifs://udfs/weather_data_enrich.py'
WITH OPTIONS (SET_ENVIRONMENT = 'sensor_py_environment');
/* SQL Block End */


/* TEXT Block Start */
/*
Schedule Weather UDF Execution Using Stored Procedure
To simulate a continuously updating stream of weather data, we create a stored procedure that runs the weather enrichment UDF every 5 minutes for a duration of 2 hours. This ensures the weather_lookup table remains up to date with the latest weather conditions based on device locations.
The procedure executes the Python UDF weather_data_enrich.py, which fetches real-time metrics from the OpenWeather API and inserts them into the weather_lookup table. The longitude and latitude are set to Boston by default, but they can be changed in the parameters.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE PROCEDURE json_extraction.sp_stream_weather_to_lookup
BEGIN
    EXECUTE FUNCTION weather_data_enrich (
        OUTPUT_TABLE_NAMES => OUTPUT_TABLES('json_extraction.weather_lookup'),
        PARAMS => KV_PAIRS(latitude = '42.36', longitude = '-71.05')
    );
END
EXECUTE FOR EVERY 5 MINUTES
STOP AFTER 2 HOUR;

--To manually start the streaming process:
EXECUTE PROCEDURE json_extraction.sp_stream_weather_to_lookup;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM json_extraction.weather_lookup;
/* SQL Block End */


/* Worksheet: Creating a Real Time Sensor Alert Table */
/* Worksheet Description:  */


/* TEXT Block Start */
/*
Create a Real-Time Sensor Alert Table Joining Weather and Sensor Data
To detect anomalies in real-time, we combine sensor readings with contextual weather data. Both data streams—sensor metrics and weather metrics—are refreshed every 5 minutes during a 2-hour simulation window.
By joining these two data sources using an ASOF (as-of) join on timestamp and device location, we can detect patterns and trigger alerts for abnormal behavior, such as device temperature significantly exceeding ambient temperature.
After joining the sensor and weather metrics, to identify abnormal behavior using thresholds:
-

Temperature Alert:
Triggered when the device's internal temperature deviates by more than 1% from the weather temperature. Note that is a purposefully low threshold for demo purposes (so that the alert getes triggered a lot).
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Sensor and weather data often arrive at different times, so directly joining them using exact timestamps can result in mismatches. To accurately associate each sensor reading with the most relevant weather conditions, we use an ASOF (As-Of) join.
An ASOF join matches each sensor record with the closest preceding weather record within a defined time range. In our case, we use:
- INTERVAL '-5' MINUTES as the search precision, meaning the join looks backward up to 5 minutes.
- INTERVAL '10' MINUTES as the maximum search range, allowing a total matching window of 15 minutes (from 5 minutes before to 10 minutes after the sensor timestamp).
- The MIN keyword selects the earliest matching weather record within that time window.
This approach ensures that each sensor reading is paired with the most temporally relevant weather data, even when the two streams are not perfectly synchronized.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW json_extraction.mv_sensor_alerts 
REFRESH ON CHANGE AS
(
    WITH joined AS (
        SELECT 
            s.device_id,
            s.last_updated AS sensor_updated_at,
            w.last_updated AS weather_updated_at,
            s.temperature AS sensor_temp_f,
            ROUND(w.weather_temp_c * 9.0/5.0 + 32, 2) AS weather_temp_f, --convert to fahrenheit
            ROUND
            (
              s.temperature 
              - (w.weather_temp_c * 9.0/5.0 + 32),
              2
            ) AS delta_temp_f
        FROM json_extraction.sensor_data s
        JOIN json_extraction.weather_lookup w 
            ON ASOF(
                s.last_updated, 
                w.last_updated, 
                INTERVAL '-5' MINUTES, 
                INTERVAL '10' MINUTES, 
                MIN
            ) -- ASOF JOIN
    )
    SELECT 
        *, 
        CASE 
            WHEN ABS(delta_temp_f) / NULLIF(weather_temp_f, 0) > 0.1
            THEN CONCAT('⚠️ TEMPERATURE ALERT: ΔT is greater than 0.1 at', NOW())
            ELSE NULL
        END AS alertNotification
    FROM joined
);
/* SQL Block End */


/* Worksheet: Adding Webhook Alerts */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
🚨 Generate Webhook Alerts from Detected Sensor Anomalies
Once anomalies have been detected and recorded in the mv_sensor_alerts materialized view, the next step is to send these alerts to external systems so that teams can take immediate action.
A common use case is to send real-time alerts to a Slack channel, email system, or incident management tool—allowing operations or engineering teams to respond quickly.
In Kinetica, you can use a stream to publish changes from a table (like mv_sensor_alerts) to a target destination. This target could be a webhook, a Kafka topic or any other compatible external service.
Try It Yourself with Webhook.site
For testing purposes, the easiest way to try out webhook alerts is by using Webhook.site:
- Visit https://webhook.site.
- A unique URL will be generated for you automatically.
- Use this URL as the target endpoint for your stream configuration.
Once the stream is active, head back to the Webhook.site page to observe incoming HTTP requests in real time.
This lets you visually confirm that alerts are being triggered and sent correctly—making it a great way to test before integrating with messaging systems like Slack.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM ki_home.webhook_alerts
ON TABLE json_extraction.mv_sensor_alerts
REFRESH ON CHANGE
WITH OPTIONS 
(
    DESTINATION = 'ADD WEBHOOK URL HERE'
);
/* SQL Block End */

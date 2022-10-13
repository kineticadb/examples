/* Workbook: Real-Time Financial Risk */
/* Workbook Description: In this demo, we set up a real-time risk monitoring system with Kinetica that alerts investors as and when portfolio values fall below certain thresholds. This is a really simple demo that solves a challenging problem. The steps broadly are the following.
1. Plug into streaming and static data sources and load the data into relational tables in Kinetica
2. Setup a continuously updated risk monitoring view that combines portfolio holdings data with real time stock prices
3. Setup up alerts via webhooks and/or sink the data to a Kafka topic
All of this is done with just a few simple SQL statements and relational tables. */


/* Worksheet: About this demo */
/* Worksheet Description: Description
 */


/* TEXT Block Start */
/*
PEEKING REAL-TIME INTO THE WORLD'S TOP INVESTORS
Many of the world's storied investors are Hedge Funds. Unlike mutual funds, to which most people have access to, hedge funds cater to institutions and wealthy investors. Fortunately, four times a year, we get a peek into this secretive world by way of regulatory filings. Hedge funds holdings give us a unique view into their thinking c/o the bets they are making.
While holdings are published only quarterly, we have real-time information on the value of their known holdings -- so we can walk-forward the value of their holdings. This has traditionally been an academic curiosity, but with recent hedge fund blow-ups, this is now a practical exercise as well.
In this demo, we show how Kinetica can be used to set up a risk monitoring system that automatically triggers alerts based on shifts in portfolio values.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
DATASETS
We will be using three datasets to drive our optimizations:
Two are static files, both hosted in an S3 bucket on AWS:
- SEC 13-F filings (up to Q1 - 2021)
- End of day price file (for Jan-29th, 2021)
The final dataset is a 24-7 real-time stream of real exchange prices that simulates market movements. This is available as a Kafka topic that can be consumed directly from Confluent Cloud.
*/
/* TEXT Block End */


/* Worksheet: 1. Load the data */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
The steps for loading data
The process for ingesting data from remote data sources is listed below. The first two steps are optional but recommended.
1. Create a Schema (Optional): Schemas are containers for tables and other database objects that provide a unique namespace within them. Tables that are created without a schema specified will be placed in the default schema
ki_home
.
2. Create the table (Optional): Kinetica has a robust type inferencing system that can infer column specifications as the data is being ingested. If you skip this step, Kinetica will infer the types and create the table when the data is being ingested.
3. Create the data source: Remote data storage locations need to be registered as data sources.
4. Load the data: There are a few different ways to do this. The most straightforward way is to use the LOAD INTO command to ingest the data into a Kinetica cluster. Tables that are loaded in this manner are persisted on the cluster.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the filings table
CREATE OR REPLACE TABLE filings_quarterly
(
   "company" VARCHAR (128, DICT) NOT NULL,
   "filing" DATETIME NOT NULL,
   "y" INTEGER NOT NULL,
   "m" INTEGER NOT NULL,
   "Stock" VARCHAR NOT NULL,
   "Symbol" VARCHAR (64, DICT) NOT NULL,
   "Type" VARCHAR (32) NOT NULL,
   "Shares_Held" DECIMAL(18,4) NOT NULL,
   "Market_Value" DECIMAL(18,4) NOT NULL,
   "pct_Portfolio" DECIMAL(18,4),
   "Change_in_shares" DECIMAL(18,4) NOT NULL,
   "Change_Type" VARCHAR (64, DICT),
   "pctOwnership" VARCHAR (64) NOT NULL,
   "sector" VARCHAR (128, DICT) NOT NULL,
   "source_type" VARCHAR (32) NOT NULL,
   "source_date" VARCHAR (32) NOT NULL,
   "AvgPrice" DECIMAL(18,4)
);
/* SQL Block End */


/* SQL Block Start */
-- Create the EOD price table
CREATE OR REPLACE TABLE px_eod
(
   "Symbol" VARCHAR (8, DICT) NOT NULL,
   "Date" VARCHAR (16, DICT) NOT NULL,
   "Open" DECIMAL(18,4),
   "High" DECIMAL(18,4),
   "Low" DECIMAL(18,4),
   "Close" DECIMAL(18,4),
   "Volume" INTEGER
);
/* SQL Block End */


/* SQL Block Start */
-- Create the table for real time exchange rate
CREATE OR REPLACE TABLE px_streaming_quotes
(
   "symbol" VARCHAR (8, DICT) NOT NULL,
   "px_last" DOUBLE NOT NULL,
   "px_timestamp" DATETIME NOT NULL,
   "size" SMALLINT NOT NULL
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE STATIC DATA SOURCE
Both the static datasets are available via a public S3 bucket - guidesdatapublic. We register a data source called 13F that references this externally maintained data. Note that we are not using any credentials to access this data because the permissions on the S3 bucket are set to be public. See the section below
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE static_13F
LOCATION = 'S3' 
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'guidesdatapublic',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE STREAMING DATA SOURCE
The real time exchange rate data is maintained as a Kafka topic on Confluent cloud. First we will create a credential and then we create the data source.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE CREDENTIAL fin_risk_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'FKHU5OKQSM6J3FZY',
   'sasl.password' = 'BT0b0049Q016ncuMUD0Pt5bRPr6YZu9YNioEtGqfuaN1pPmwyPUVMytUWloqtt8o'
   );
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE streaming_13F
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'px-equities-trades',
    credential = 'fin_risk_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD DATA
Now that we have defined the data sources, we can load the data that is located in them to tables in Kinetica (that we defined earlier).
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD DATA INTO filings_quarterly
FROM FILE PATHS '13F/consolidated.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'static_13F'
);
/* SQL Block End */


/* SQL Block Start */
LOAD DATA INTO px_eod
FROM FILE PATHS '13F/pxeod.csv'
FORMAT TEXT
WITH OPTIONS (
    DATA SOURCE = 'static_13F'
);
/* SQL Block End */


/* TEXT Block Start */
/*
The streaming ingest below will continuously ingest data from the Kafka topic.
✎ NOTE
: The last sheet in the workbook contains code to pause the subscription. Make sure to do so to prevent taking up too much disk space.
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD DATA INTO px_streaming_quotes
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'streaming_13F',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    POLL_INTERVAL = '5 seconds'
);
/* SQL Block End */


/* Worksheet: 2. Set up the views */
/* Worksheet Description: Setup the different materialized views that will feed that alerts */


/* TEXT Block Start */
/*
Filter the most recent quarterly filing
The 13F quarterly filing data has filings from several quarters and includes information on derivatives as well as stock holdings. We however, only need stock holdings data from the most recent quarter, which is for Q1 - 2021. Kinetica supports the creation of materialized views. We can use that to create a view with the data we need.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW recent_filing AS
SELECT * 
    FROM filings_quarterly 
    WHERE 
        filing=(select max(filing) from filings_quarterly) AND 
        type NOT IN ('CALL', 'PUT');
/* SQL Block End */


/* TEXT Block Start */
/*
The traditional approach to risk management
Combine portfolio holdings with share prices at the end of the day to get an estimate of the overall values. This would then be fed into some downstream estimate for risk.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE or REPLACE MATERIALIZED VIEW holdings_eod
REFRESH ON QUERY AS 
SELECT company, SUM(fq.Shares_Held*p.High) as Total_Current_Value
FROM recent_filing fq, px_eod p
WHERE fq.Symbol = p.Symbol
GROUP BY company;

SELECT * FROM holdings_eod;
/* SQL Block End */


/* TEXT Block Start */
/*
The real time approach to risk management
Combines a streaming second by milli-second view on portfolio holdings. Kinetica offers materialized views that can be used to set up queries that are continuously refreshed when new data is received via a streaming ingest. The code below computes a measure of change in overall portfolio value from the earliest price values in a day with the most recent.
Note
: Even though we are looking at a static representation of portfolio holdings that is being combined with a streaming prices data, Kinetica can easily combine two different streaming data sources as well. This is possible even when the two data streams are being recorded on different timestamps (using ASOF joins).
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE or REPLACE MATERIALIZED VIEW holdings_streaming_scaled
REFRESH EVERY 5 SECONDS AS 
SELECT 
    company, 
    100 * (
        SUM(fq.Shares_Held*p.px_last) / 
        SUM(fq.Shares_Held*p_earliest.px_last)
        ) as "portfolio_change", 
    p.px_timestamp 
    FROM 
        recent_filing fq, 
        px_streaming_quotes p, 
        px_streaming_quotes p_earliest
    WHERE 
        p_earliest.Symbol = fq.Symbol AND 
        p_earliest.px_timestamp = 
            (SELECT MIN(px_timestamp) FROM px_streaming_quotes) AND 
        fq.Symbol=p.Symbol
    GROUP BY p.px_timestamp, company
    ORDER BY p.px_timestamp;
/* SQL Block End */


/* TEXT Block Start */
/*
Portfolio Alerts
The table calculates a materialized view of the change in portfolio value that refreshes itself every 5 seconds. We can use that to create another alert table that records whenever the change in portfolio value crosses a certain threshold.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW portfolio_alert
REFRESH EVERY 5 SECONDS AS 
SELECT *
FROM holdings_streaming_scaled p
WHERE (100 - p.portfolio_change) > 0.001;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM portfolio_alert;
/* SQL Block End */


/* Worksheet: 3. Set up outbound decisioning */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
Set up automated alerts
Now that we have the views created, we can set up alerts based on certain triggers. There are a few different ways to do it. We could set up a Kafka data sink that receives all new records from the portfolio alert table that we created in the previous sheet. We can use webhooks to setup alerts on applications like Slack etc.
For this demo, we recommend using the website: https://webhook.site/ to generate a webhook URL. Copy the webhook URL and paste it as the destination in the stream below. This will send alerts to that URL.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE STREAM alert_webhook_fin_risk
ON TABLE portfolio_alert
WITH OPTIONS 
(
    DESTINATION = 'WEBHOOK_URL' -- 'Paste your Webhook URL (see above)'
);
/* SQL Block End */


/* TEXT Block Start */
/*
Slack alerts
The pattern above can be used to setup slack alerts as well. You can follow the instructions here: https://api.slack.com/messaging/webhooks, if you would like to implement this on your own.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE STREAM alert_slack_fin_risk
-- ON TABLE portfolio_alert
-- WITH OPTIONS 
-- (
--     DESTINATION = 'https://hooks.slack.com/services/<ENTER YOUR KEY>'
-- );
/* SQL Block End */


/* TEXT Block Start */
/*
Kafka sink
You can also send the alerts to a Kafka topic. Uncomment the code below and update the details for your Kafka cluster to point the alerts to a Kafka topic, which can then be used in downstream analytics or triggers.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE OR REPLACE DATA SINK fin_risk_sink
-- LOCATION = '<kafka cluster address>'
-- WITH OPTIONS 
-- (
--     'kafka_topic_name' =  'topic name',
--     credential = 'your credentials'
-- );
/* SQL Block End */


/* SQL Block Start */
-- CREATE STREAM portfolio_alert_stream on 
-- TABLE portfolio_alert
-- WITH OPTIONS 
-- (
--     event = 'insert', 
--     datasink_name = 'fin_risk_sink'
-- );
/* SQL Block End */


/* Worksheet: ❗️PAUSE SUBSCRIPTION */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
PAUSE SUBSCRIPTIONS
The Kafka topic that we are subscribed to is always on. So data will continue to load into the connected Kinetica table unless we pause the subscription. You can follow the instructions here (https://docs.kinetica.com/7.1/sql/ddl/#manage-subscription) to resume your subscription anytime you would like to
*/
/* TEXT Block End */


/* SQL Block Start */
ALTER TABLE px_streaming_quotes
PAUSE SUBSCRIPTION streaming_13F;
/* SQL Block End */

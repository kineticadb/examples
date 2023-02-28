/* Workbook: Time Series Analysis */
/* Workbook Description: Common time series functions and use cases. */


/* Worksheet: Data */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
SET UP THE KAFKA DATA SOURCE
There are two kafka topics that we will use for this example. The first contains data on quotes and the second on trades. The queries below register both these data sources.
✎ Note
: Both the data streams are synthetic i.e. made up data. They don't correspond to actual prices and they are always on i.e. they don't follow market hours. This is to ensure that anyone accessing these feeds will have access to a running feed regardless of timezone. However, both the streams are similar intraday trade and quote streams in terms of values and number of observations.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Drop any existing tables that subscribe to these data sources
DROP TABLE IF EXISTS quotes;
DROP TABLE IF EXISTS trades;

-- Create the credentials for the kafka cluster
CREATE OR REPLACE CREDENTIAL trade_quote_creds
TYPE = 'kafka',
IDENTITY = '' ,
SECRET = ''
WITH OPTIONS (  
   'security.protocol' = 'SASL_SSL',
   'sasl.mechanism' = 'PLAIN',
   'sasl.username' = 'QZN62QB2RBTLW74L',
   'sasl.password' = 'iiJDdKeBzf5ms5EInLvpRslW1zwsTYx9tjZ1pQyVoS+gPGkyNms6eMXPaR6y+GST'
);

-- Create the quote source
CREATE OR REPLACE DATA SOURCE quote_stream
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'quotes',
    credential = 'trade_quote_creds'
);

-- Create the trade stream
CREATE OR REPLACE DATA SOURCE trade_stream
LOCATION = 'kafka://pkc-ep9mm.us-east-2.aws.confluent.cloud:9092'
WITH OPTIONS 
(
    kafka_topic_name =  'trades',
    credential = 'trade_quote_creds'
);
/* SQL Block End */


/* TEXT Block Start */
/*
QUOTES DATA
The quotes table contains information on the ask and bid prices on a millisecond basis for three stocks - Apple (AAPL), Amazon (AMZN) and Google (GOOG).
✎Note
: We are loading only the latest quotes from kafka unlike trades, where we load from the earliest available data.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE quotes
(
 timestamp timestamp,
 ask_price float,
 ask_size float,
 bid_price float,
 bid_size float,
 symbol char(4)
);

LOAD DATA INTO quotes
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'quote_stream',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_offset_reset_policy = 'latest', -- load the latest qoutes data
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* TEXT Block Start */
/*
INTRADAY TRADES
The trades table contains information on the open, close, low, and high prices, and trading volumes for AAPL, AMZN and GOOG. The trades data is recorded on a minute by minute basis.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE trades 
(
    time timestamp,
    symbol char(4),
    price_open float,
    price_close float,
    price_low float,
    price_high float,
    trading_volume int
);

LOAD DATA INTO trades
FORMAT JSON 
WITH OPTIONS (
    DATA SOURCE = 'trade_stream',
    SUBSCRIBE = TRUE,
    TYPE_INFERENCE_MODE = 'speed',
    ERROR_HANDLING = 'permissive',
    kafka_subscription_cancel_after = 120 -- cancels the stream after 120 minutes
);
/* SQL Block End */


/* Worksheet: Primer */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
Feel free to skip this section if you are already familiar with the basics of time series analysis with SQL
WHAT IS TIME SERIES DATA
Time-series data are a set of observations collected over a period of time. It is often used to track trends over time, such as stock prices, weather patterns, or economic indicators.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
KEY ANALYTICAL CAPABILITIES FOR TIME SERIES ANALYSIS
Analysis of time series data requires specialized operations. These include the following.
1.
Date/time objects
: Kinetica provides extended coverage and support for data/time objects and convenience functions for manipulating and working with them. This is essential for dealing with time series data.
2.
Window functions
: Window functions are useful for time series analysis because they allow us to analyze data in a rolling or sliding window. This is useful for understanding patterns in the data that may not be visible when looking at the whole dataset. For example, if we wanted to identify seasonality in a time series, we could use a window function to calculate the average of a given period of time (e.g., a month, a quarter, etc.) and then compare it to the overall average at different points throughout the year. This can help us identify any patterns that may be present in the data.
3.
Inexact joins:
Timestamp values from two different IoT sensors rarely align. This makes it impossible to join these data streams on equality based joins. Range based joins solve this problem by searching for matches within an interval. Kinetica provides an ASOF function for these types of use cases.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
TIME SERIES CHART (AMZN and GOOG)
The query below find the highest traded price every day for Amazon and Google. The chart is an illustration of time series data. Run the query to see the chart update.
✎ Note
: Rerun the query to show the most up to date version of the chart. You might need to wait a couple of minutes for the data to show up.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT
    symbol,
    DATE(CONCAT(CONCAT(CONCAT(YEAR(time), '-'), CONCAT(MONTH(time), '-')), CONCAT(DAY(time), ''))) AS trade_date,
    MAX(price_high) as price_high
FROM trades 
WHERE symbol != 'AAPL'
GROUP BY trade_date, symbol
ORDER BY trade_date, symbol;
/* SQL Block End */


/* Worksheet: Date Time Functions */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
Time series analysis often requires the manipulation of data and time values. Kinetica offers a wide range of functions to work with data and time. I will demonstrate a few here, but you can read more about them here: https://docs.kinetica.com/7.1/sql/query/#sql-datetime-functions
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CALCULATE THE DIFFERENCE BETWEEN TWO DATES
Let's find the total duration in days of the trades data.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT TIMESTAMPDIFF(DAY, MIN(time), MAX(time)) AS days_duration
FROM trades;
/* SQL Block End */


/* TEXT Block Start */
/*
FIND THE DATE RANGE OF THE DATA
The data starts from November 8 till December 12th in 2022.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT 
    DAY(MIN(time)) as start_day,
    MONTH(MIN(time)) as start_month,
    YEAR(MIN(time)) as start_year,
    DAY(MAX(time)) as end_day,
    MONTH(MAX(time)) as end_month,
    YEAR(MAX(time)) as end_year
FROM trades;
/* SQL Block End */


/* TEXT Block Start */
/*
Let's use the TIMESTAMPDIFF function to find the total number of hours of quotes data we have.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT TIMESTAMPDIFF(HOUR, MIN(timestamp), MAX(timestamp)) AS total_hrs_avl
FROM quotes;
/* SQL Block End */


/* TEXT Block Start */
/*
DATE/TIME CONVERSION FUNCTIONS
Kinetica also offers functions that can be used to convert between different data time formats.
Let's use the DATE_TO_EPOCH_MSECS(year, month, day, hour, min, sec, msec) function to convert the time column in the trades data to milliseconds since the UNIX epoch (Jan 1, 1970).
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT DATE_TO_EPOCH_MSECS(INT(YEAR(time)), INT(MONTH(time)), INT(DAY(time)), INT(HOUR(time)), INT(MINUTE(time)), INT(SECOND(time)), INT(MSEC(time))) as ms_time 
FROM trades;
/* SQL Block End */


/* Worksheet: Moving Average */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
MOVING AVERAGES
Moving averages are used in time series analysis to smooth out short-term fluctuations and highlight longer-term trends. The average of a set of data points is calculated and a line is drawn through the average values to show the overall trend. This can help analysts identify patterns and make predictions about future data points. Moving averages are also used to identify support and resistance levels, which can be useful for making trading decisions.
Let's use a window function to find the  5 minute moving average of closing prices and then compare the current closing price with the moving average. We will do this in two stages. First we will compute the moving average over 10 preceding minutes and then compute the gap. We will then aggregate up to the hour interval to compute the average hourly gap.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Calculate the price gap when compared to a moving average for a 10 minute window
CREATE OR REPLACE MATERIALIZED VIEW mv_mov_avg_minute
REFRESH EVERY 5 SECONDS AS
SELECT
    time,
    symbol,
    ROUND
    (
        (price_close - (AVG(price_close) OVER 
        (
            PARTITION BY symbol
            ORDER BY time
            ROWS 5 PRECEDING
        ))),
        2
    ) AS price_gap
FROM trades
WHERE TIMEBOUNDARYDIFF('HOUR', time, NOW()) < 24 --Only keep the last 24 hours
ORDER BY time, symbol;

-- Find the average hourly price gap
CREATE OR REPLACE MATERIALIZED VIEW price_gap_hourly 
REFRESH ON CHANGE AS 
SELECT 
    symbol,
    HOUR(time) as time_hour,
    ROUND(AVG(price_gap), 2) AS price_gap
FROM mv_mov_avg_minute
GROUP BY symbol, time_hour 
ORDER BY time_hour, symbol;

-- Plot that on a line chart
SELECT * FROM price_gap_hourly;
/* SQL Block End */


/* Worksheet: Cumu. Sum */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
CUMULATIVE SUM
Cumulative sums are used to analyze the total effect of a given event over a period of time. It provides insight into the trend of a particular variable by summing all values from a given starting point up to the present. This can help identify changes in the data and detect patterns in the underlying data. Additionally, cumulative sums can be used to compare two different time series and analyze the difference between them.
Let's compare the cumulative hourly sum of traded stocks for the last 24 hours of trading data. We will need to do this two stages. First we calculate the hourly total volume and then we calculate the cumulative totals.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Find the hourly total volume
CREATE OR REPLACE MATERIALIZED VIEW hourly_volumes
REFRESH EVERY 5 SECONDS AS 
SELECT 
    symbol,
    HOUR(time) AS time_hour,
    SUM(trading_volume) AS total_volume
FROM trades
WHERE TIMEBOUNDARYDIFF('HOUR', time, NOW()) < 24 --Only keep the last 24 hours
GROUP BY time_hour, symbol;

-- Find the cumulative totals
CREATE OR REPLACE MATERIALIZED VIEW hourly_cumu_volumes
REFRESH ON CHANGE AS 
SELECT
    symbol,
    time_hour,
    SUM(total_volume) OVER 
    (
        PARTITION BY symbol
        ORDER BY time_hour 
    ) AS cumu_volume
FROM hourly_volumes
ORDER BY time_hour, symbol;

SELECT * FROM hourly_cumu_volumes;
/* SQL Block End */


/* Worksheet: Ranking */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
RANKING
Ranking is used to compare data points within a given series or between different series and determin their relative importance. There are several types of ranking functions available.
https://docs.kinetica.com/7.1/concepts/window/#ranking
Let's use the rank function to find the top 5 percent positve changes in closing price over a ten minute window. This will require two different queries. The first will find the percent change in closing price over a moving 10 minute window. The second will rank these and slice the top 5.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW percent_changes
REFRESH EVERY 5 SECONDS AS 
SELECT  
    symbol,
    time,
    (price_close - LAG(price_close, 10) OVER 
    (
        PARTITION BY symbol
        ORDER BY time 
    )) / LAG(price_close, 10) OVER 
    (
        PARTITION BY symbol
        ORDER BY time 
    ) AS percent_change_10_mins
FROM trades
ORDER BY time, symbol;

CREATE OR REPLACE MATERIALIZED VIEW top_changes
REFRESH ON CHANGE AS 
SELECT 
    symbol,
    DATETIME(time),
    percent_change_10_mins * 100 AS percent_change_10mins,
    RANK() OVER 
    (
        PARTITION BY symbol
        ORDER BY percent_change_10_mins DESC
    ) AS change_rank 
FROM percent_changes
ORDER BY change_rank;
/* SQL Block End */


/* SQL Block Start */
-- Display the results
SELECT * FROM top_changes;
/* SQL Block End */


/* Worksheet: ASOF joins */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
HIGH CARDINALITY JOINS ON STREAMING DATA USING ASOF
An ASOF join is used in time series analysis when combining data from two different sources (e.g., two different databases or two different time periods) that have slightly different time stamps. This type of join is used to match up entries with similar values, but that have slightly different time stamps, by pairing them with the closest corresponding value in the other dataset. This allows for data points to be accurately matched and combined, even if the timing of the events is slightly off.
TRIGGER SELL WHEN BID PRICE HIGHER THAN HIGHEST TRADED PRICE
Kinetica allows you to perform high cardinality ASOF joins on streaming data to maintain an always updated view. Let's use that to combine the trades data with quotes to trigger buy events if the bid price is higher than the highest traded price in the last minute.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE MATERIALIZED VIEW trade_quotes 
REFRESH EVERY 5 SECONDS AS
SELECT 
    DATETIME(time) AS time,
    t.symbol AS symbol,
    price_high,
    bid_price
FROM trades t 
INNER JOIN quotes q ON 
t.symbol = q.symbol AND 
ASOF(t.time, q.timestamp, INTERVAL '0' SECOND, INTERVAL '1' SECOND, MIN)
WHERE bid_price > price_high;
/* SQL Block End */


/* TEXT Block Start */
/*
THE ASOF JOIN
An ASOF function allows you to perform an inexact join by specifying a window within which to look for matching values. The positioning of this window is configurable and so is the method by which a specific matching value is picked when there are multiple matches within that window.
*/
/* TEXT Block End */


/* Worksheet: Stream events */
/* Worksheet Description: Description for sheet 8 */


/* TEXT Block Start */
/*
EVENT STREAMING
Let's say we want to trigger an event alert anytime there is a new sell decision using the ASOF query that we saw in the previous worksheet. We can does using a stream. A stream can send records from Kinetica into other data sinks like Kafka or a simple webhook.
SEE EVENTS BEING STREAMED IN REAL TIME
For this illustration, we will use the latter to send records to a pipedream webhook and then hook that up to the following google spreadsheet: https://bit.ly/3ExmTVC
Copy the link above and paste in your browsers address bar to see buy events being detected in real time by Kinetica.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE A STREAM 
CREATE STREAM buy_events ON trade_quotes 
REFRESH ON CHANGE 
WITH OPTIONS 
(
    DESTINATION = 'https://eofzvoul4mtk60x.m.pipedream.net' 
);
/* SQL Block End */

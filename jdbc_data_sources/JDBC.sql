/* Workbook: JDBC */
/* Workbook Description: Showcase JDBC data source capabilities */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
✎ NOTE
This workbook showcases certian admin features that will only work in developers edition and not on Kinetica cloud.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
JDBC DATA SOURCES
Java DataBase Connectivity (JDBC) is a standardized API for interacting with databases using Java programs. Kinetica offers a data source that can be used to connect to other databases and applications using a JDBC driver. We can then issue remote queries to this data source to load and export data to and from Kinetica into this data source.
CDATA
Kinetica has also partnered with CData, which is a data connectivity platform that offers jdbc drivers for 100s of different databases and applications.
TWO ROUTES
There are two ways to register a JDBC data source. You can either Bring Your Own Driver (BYOD) or you can use a driver provided by CData.
THIS DEMO
In this demo, we explore both the BYOD and CData route. First we will use a CData driver to load data from googlesheets into Kinetica and then we will bring our own JDBC driver to connect to a Postgres database.
*/
/* TEXT Block End */


/* Worksheet: Googlesheets */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
CREATE SCHEMA
Tables in Kinetica are organized using schema. We will use the 'jdbc' schema to organize the tables and data objects for this example.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the schema
CREATE SCHEMA IF NOT EXISTS jdbc;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCE
Paste the authorization code that you generated (see prerequisites) earlier as the value for OAuthVerifier in the query below (LOCATION parameter).
✎
Note
: The CDATA connector is specified separately for each spreadsheet.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the JDBC data source that points to the nyct2010 google spreadsheet
CREATE OR REPLACE DATA SOURCE jdbc.gsheets
LOCATION = 'jdbc:cdata:googlesheets:OAuthVerifier=PASTE YOUR AUTH CODE HERE;InitiateOAuth=REFRESH;Spreadsheet=nyct2010';
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE TABLE
While Kinetica has a good type inferencing system, it is always a best practice to define the table schema before loading data into it.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE MATERIALIZED EXTERNAL TABLE "jdbc"."nyct2010"
(
    "id" INTEGER NOT NULL,
    "gid" INTEGER (primary_key) NOT NULL,
    "geom" GEOMETRY,
    "CTLabel" VARCHAR (16),
    "BoroCode" VARCHAR (16),
    "BoroName" VARCHAR (16),
    "CT2010" VARCHAR (16),
    "BoroCT2010" VARCHAR (16),
    "CDEligibil" VARCHAR (16),
    "NTACode" VARCHAR (16),
    "NTAName" VARCHAR (64),
    "PUMA" VARCHAR (16),
    "Shape_Leng" DOUBLE,
    "Shape_Area" DOUBLE
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD THE DATA
Data is loaded by issuing a query to the remote data source.
✎ Note:
The googlesheets API uses the syntax spreadsheet_sheetName to identify the sheet from which to load the data.
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD INTO jdbc.nyct2010
FROM REMOTE QUERY 'SELECT * FROM nyct2010_Sheet1'
WITH OPTIONS 
(
    DATA SOURCE = 'jdbc.gsheets',
    ON ERROR = SKIP 
);
/* SQL Block End */


/* Worksheet: Postgres */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
POSTGRES DATABASE
Postgres is a very popular open source relational database management system. The worksheets shows how to connect to an instance of Postgres using JDBC.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCE
The credential for accessing the postgres database (if using the docker version in pre-reqs) is postgres. Make sure the postgres database is up and running before registering the data source.
✎ Note
: The data source is registered for dellstore. You can try replacing it with other datasets.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE jdbc.postgres_ds
LOCATION = 'jdbc:postgresql://172.17.0.3:5432/dellstore'
USER = 'postgres'
PASSWORD = 'postgres'
WITH OPTIONS
(
  JDBC_DRIVER_JAR_PATH = 'kifs://drivers/postgresql-42.4.0.jar',
  JDBC_DRIVER_CLASS_NAME = 'org.postgresql.Driver'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD DATA
In the query below, we use Kinetica's type inferencing system to directly load the data from postgres into a table without having created the table in Kinetica first.
*/
/* TEXT Block End */


/* SQL Block Start */
LOAD INTO jdbc.products
FROM REMOTE QUERY 'SELECT * FROM products'
WITH OPTIONS 
(
    DATA SOURCE = 'jdbc.postgres_ds'
);
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM jdbc.products;
/* SQL Block End */

/* Workbook: Origin-Destination Pair Batch Solver */
/* Workbook Description: MULTIPLE_TSM_DC */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
This SQL workbook showcases how to leverage Kinetica’s "match_batch" graph solver, a powerful tool designed for, optimal Origin-Destination(O-D) path calculation. This workbook walks you through a scenario involving 2 supply locations and 5 demand locations in the Washington DC area. The solver will calculate the most optimal O-D path between all supply and demand locations and provide the optimal path for each pair.
This analysis has the following steps:
Data Sheet:
- Load data sources
- Create and populate tables
- Create a graph representation of the Washington DC road network.
Batch Solve Sheet:
- Create OD pairs
- Run the "match_batch" solver
- Find the optimal path for each supply and demand location pairs.
- Understand the output of "match_batch" solver
HOW TO RUN?
All the steps and instructions are provided within the workbook itself.
To ensure successful execution of the workbook, it is essential to adhere to the prescribed order of blocks and sheets. We will create all the necessary data sources and download the required data into our workbook.
*/
/* TEXT Block End */


/* Worksheet: Data */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCES
We will be using a data source called "batch_tsm". This data source contains raw spatial data table.
Our first task is to register the data source so that we can connect to them.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE batch_tsm
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE & LOAD DATA
In the next step, we will load the spatial data. Then create demand and suppliers tables and populate them with data.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS dc;
LOAD DATA INTO dc 
FROM FILE PATHS 'dc/dc_roads.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'batch_tsm'
);

CREATE OR REPLACE TABLE origin
(wkt WKT NOT NULL, 
id INT NOT NULL, 
size FLOAT NOT NULL, 
supply_id INT NOT NULL);

CREATE OR REPLACE TABLE destination 
(wkt WKT NOT NULL, 
id INT NOT NULL, 
demand_id INT NOT NULL, 
size FLOAT NOT NULL);
/* SQL Block End */


/* SQL Block Start */
--Populating Origin Table With Two Different Records
INSERT INTO origin VALUES
('POINT(-77.116787 38.885892)',1,2,1), 
('POINT (-77.015707 38.904309)', 2, 3, 2);

--Populating Destination Table Wuth Five Different Records
INSERT INTO destination VALUES 
('POINT (-77.088237 38.895701)', 10, 1, 1.0), 
('POINT (-77.150693 38.892861)', 50, 1, 1.0), 
('POINT( -76.956383 39.071894)', 20, 2, 1.0), 
('POINT (-77.069505 38.91801)', 30, 2, 1.0), 
('POINT (-77.063653 38.908072)', 40, 2, 1.0);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH dc 
    (EDGES => INPUT_TABLE (
        SELECT  id  AS ID,
            wkt AS WKTLINE,                                            
            dir AS DIRECTION,
            time  AS WEIGHT_VALUESPECIFIED
        FROM dc),
        OPTIONS => KV_PAIRS
        ( 
            graph_table = 'dc_area_graph'
        )
    );
/* SQL Block End */


/* Worksheet: Batch Solve */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
IN THIS SHEET
In this sheet, we will create a new table that pairs the suppliers and demands locations. Next, we'll calculate the distances between each supplier and demand location to determine the optimal path connecting them using Kinetica's 'match_batch_solves' solver.
CREATE PAIRS TABLE
We are in the process of creating a new table called 'dc_pairs.' This table is designed to match two supply locations with all five demand locations, resulting in 10 different O-D pairs, each linked to a unique ID. Within each pair, there will be an origin (supplier location) and a destination (demand location). The 'dc_pairs' table will subsequently be utilized to compute the optimal cost(Time in Seconds) for each combination using Kinetica's 'match_batch_solves' solver.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE VIEW dc_pairs AS
SELECT origin.id+destination.id AS id, origin.wkt AS origin, destination.wkt AS destination
FROM origin CROSS JOIN destination;

SELECT * FROM dc_pairs ORDER BY id;
/* SQL Block End */


/* TEXT Block Start */
/*
HOW DOES A MATCH BATCH SOLVER WORKS
A match batch solver takes the following inputs: a graph network and a pairs table of supply and demand locations. It uses these inputs to find the path with optimal cost for each pair in the table and provides the associated cost for each path.
SOLVER SPECIFICATION
In the 'solve_method' section, we opt for 'match_batch_solves,' indicating that our solver will find the optimal path for each combination in the match batch concept. The output of the solver is stored in the 'solution_table,' which is set to 'dc_shortest_path' in the following query.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS dc_optimal_paths;
EXECUTE FUNCTION MATCH_GRAPH
(
    GRAPH => 'dc',
    SAMPLE_POINTS => INPUT_TABLE 
    ( 
        SELECT 
            id AS SAMPLE_OD_ID,
            origin AS SAMPLE_ORIGIN_WKTPOINT,
            destination AS SAMPLE_DESTINATION_WKTPOINT 
        FROM ki_home.dc_pairs
    ),
    SOLVE_METHOD => 'match_batch_solves',
    SOLUTION_TABLE => 'dc_optimal_paths',
    OPTIONS => KV_PAIRS
    (
        output_tracks = 'true',
        aggregated_output   = 'true',
        svg_width = '400', svg_height = '600',  
        svg_speed = '20', svg_basemap = 'true', 
        timeout = '60'
    )
);
/* SQL Block End */


/* TEXT Block Start */
/*
OUTPUT OF THE MATCH BATCH SOLVE
It's important to familiarize ourselves with the solver's output. Run the block below to see the output, which consists of five distinct columns, each serving a specific purpose.
- The 'index' column indicates the unique identification for each path.
- The 'source' column provides coordinates for the starting location of a path.
- The 'target' column provides coordinates for the destination location of a path.
- The 'cost' column shows the total path cost, in this case, in seconds.
- The 'path' column displays the route's tracks.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT * FROM dc_optimal_paths ORDER BY index;
/* SQL Block End */

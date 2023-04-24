/* Workbook: DC_TWODEPOTS_MSDO */
/* Workbook Description: DC_TWODEPOTS_MSDO */


/* Worksheet: Sheet 1 */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
TWO DEPOTS (with 12 trucks with variable capacities) TOWARDS MULTIPLE DESTINATION VARIABLE DEMAND SIZES SPREAD AROUND DC USE CASE
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE examples_s3
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
DROP TABLE IF EXISTS dc;
DROP TABLE IF EXISTS demands_2;
DROP TABLE IF EXISTS supplies_2;

LOAD DATA INTO dc 
FROM FILE PATHS 'dc/dc_roads.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_s3'
);
LOAD DATA INTO demands_2 
FROM FILE PATHS 'dc/demands_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_s3'
);
LOAD DATA INTO supplies_2 
FROM FILE PATHS 'dc/supplies_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'examples_s3'
);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH dc 
( 
    EDGES => INPUT_TABLE 
    (
        SELECT  id  AS ID,
        wkt AS WKTLINE,                                            
        dir AS DIRECTION,
        time  AS WEIGHT_VALUESPECIFIED
        FROM dc
    ),
    OPTIONS => KV_PAIRS
    ( 
        graph_table = 'dc_graph_table'
    )
);
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS dc_msdo;
EXECUTE FUNCTION MATCH_GRAPH
(
    GRAPH => 'dc',
    SAMPLE_POINTS => INPUT_TABLES
    (
        (
            SELECT 
                id AS DEMAND_ID,
                wkt AS DEMAND_WKTPOINT,
                size AS DEMAND_SIZE,
                depot AS DEMAND_DEPOT_ID
            FROM demands_2
        ),
        (
            SELECT 
                depot AS SUPPLY_DEPOT_ID,
                wkt AS SUPPLY_WKTPOINT,
                truck_id AS SUPPLY_TRUCK_ID,
                truck_size AS SUPPLY_TRUCK_SIZE
            FROM supplies_2
        )
    ),
    SOLVE_METHOD   => 'match_supply_demand',
    SOLUTION_TABLE => 'dc_msdo',
    OPTIONS => KV_PAIRS
    ( 
        output_tracks = 'true',
        aggregated_output   = 'false',
        svg_width = '400', 
        svg_height = '600',
        svg_speed = '10',
        svg_basemap = 'true', 
        timeout= '60'
    )
);
/* SQL Block End */


/* SQL Block Start */
create or replace view dc_supplies_demands_od as
select supplies_2.wkt as origin, demands_2.wkt as target, supplies_2.depot*10+demands_2.id as id
from supplies_2 
cross join
demands_2;
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS dc_sssp2;
EXECUTE FUNCTION MATCH_GRAPH
(
    GRAPH => 'dc',
    SOLVE_METHOD => 'match_batch_solves',
    SAMPLE_POINTS => INPUT_TABLE 
    ( 
        SELECT 
            origin AS SAMPLE_ORIGIN_WKTPOINT,
            target AS SAMPLE_DESTINATION_WKTPOINT,
            id AS SAMPLE_OD_ID 
        FROM dc_supplies_demands_od
    ),
    SOLUTION_TABLE => 'dc_sssp2',
    OPTIONS => KV_PAIRS
    (
        output_tracks = 'true',
        aggregated_output   = 'true',
        svg_width = '400', 
        svg_height = '600',  
        svg_speed = '20', 
        svg_basemap = 'true', 
        timeout = '60'
    )
);
/* SQL Block End */

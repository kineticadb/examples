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
CREATE OR REPLACE DATA SOURCE quickstart
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'quickstartpublic',
    REGION = 'us-east-1'
);
DROP TABLE IF EXISTS ki_home.dc;
DROP TABLE IF EXISTS ki_home.demands_2;
DROP TABLE IF EXISTS ki_home.supplies_2;
CREATE OR REPLACE DATA SOURCE quickstart
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'quickstartpublic',
    REGION = 'us-east-1'
);
LOAD DATA INTO dc 
FROM FILE PATHS 'dc/dc.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
LOAD DATA INTO demands_2 
FROM FILE PATHS 'dc/demands_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
LOAD DATA INTO supplies_2 
FROM FILE PATHS 'dc/supplies_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'quickstart'
);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH 
                   dc ( EDGES => INPUT_TABLE (
                                           SELECT  id  AS ID,
                                                   wkt AS WKTLINE,                                            
                                                   dir AS DIRECTION,
                                                   time  AS WEIGHT_VALUESPECIFIED
                                           FROM ki_home.dc),
                              OPTIONS => KV_PAIRS( graph_table = 'ki_home.dc_graph_table')
                            );
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc_msdo;
EXECUTE FUNCTION
MATCH_GRAPH(
      GRAPH => 'ki_home.dc',
      SAMPLE_POINTS => INPUT_TABLES(
                               (SELECT id     AS DEMAND_ID,
                                       wkt    AS DEMAND_WKTPOINT,
                                       size   AS DEMAND_SIZE,
                                       depot  AS DEMAND_DEPOT_ID
                                FROM demands_2
                               ),
                               (SELECT depot AS SUPPLY_DEPOT_ID,
                                       wkt   AS SUPPLY_WKTPOINT,
                                       truck_id AS SUPPLY_TRUCK_ID,
                                       truck_size AS SUPPLY_TRUCK_SIZE
                                FROM supplies_2
                               )
      ),
      SOLVE_METHOD   => 'match_supply_demand',
      SOLUTION_TABLE => 'ki_home.dc_msdo',
      OPTIONS => KV_PAIRS( output_tracks = 'true',
                           aggregated_output   = 'false',
                           svg_width = '400', svg_height = '600',  svg_speed = '10', svg_basemap = 'true', 
                           timeout= '60')
);
/* SQL Block End */


/* SQL Block Start */
create or replace view dc_supplies_demands_od as
select supplies_2.wkt as origin, demands_2.wkt as target, supplies_2.depot*10+demands_2.id as id
from ki_home.supplies_2 
cross join
ki_home.demands_2;
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc_sssp2;
EXECUTE FUNCTION
MATCH_GRAPH(
    GRAPH => 'ki_home.dc',
    SOLVE_METHOD => 'match_batch_solves',
    SAMPLE_POINTS => INPUT_TABLE ( SELECT 
                            origin AS SAMPLE_ORIGIN_WKTPOINT,
                            target AS SAMPLE_DESTINATION_WKTPOINT,
                            id     AS SAMPLE_OD_ID 
                            FROM ki_home.dc_supplies_demands_od),
    SOLUTION_TABLE => 'ki_home.dc_sssp2',
    OPTIONS => KV_PAIRS(output_tracks = 'true',
                           aggregated_output   = 'true',
                           svg_width = '400', svg_height = '600',  svg_speed = '20', svg_basemap = 'true', timeout = '60'));
/* SQL Block End */

/* Workbook: MULTIPLE_TSM_DC */
/* Workbook Description: MULTIPLE_TSM_DC */


/* Worksheet: Sheet 1 */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
This small case is the demonstration of running travelling salesmen problem in batches - using the MSDO solver - In oder to cast the problem into MSDO context, we need to assume each salesmen as a supply side with one truck each and the capacity of the truck equal to the number of deliveries. Likewise, the stop locations will be assumed to be the demand size with the demands size of eactly one in each. Steps involved:
1. Read Graph Road Network raw data from S3 bucket
2. Create Supply and Demand tables with the note above in mind s.t., the total supplies matches total demand size exactly.
3. Run match/graph with MSDO solver.
4. Class Break Visualization of the salesmen routes on the output table by breaking on the salesmen id (SUPPLY ID).
5. Re-run match graph with animation options, i.e., svg options, by generating the tracks - option is 'output_tracks' (see below).
6. Flip the goal to a batch od shortest path runs; from supply location to every other stop (demand) location, create od matrix by the cross join of supply/demand tables and assign od id as the sum of the two
7. Run 'match_batch_solves' of /match/graph and see the result as animated svg paths.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc;
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
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE dc_supplies (wkt WKT NOT NULL, id INT NOT NULL, size FLOAT NOT NULL, truck_id INT NOT NULL);
INSERT INTO dc_supplies 
VALUES ('POINT(-77.116787 38.885892)',1,2,1), ('POINT (-77.015707 38.904309)', 2, 3, 2);
select * from dc_supplies;
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE dc_demands (wkt WKT NOT NULL, id INT NOT NULL, supply_id INT NOT NULL, size FLOAT NOT NULL);
INSERT INTO dc_demands 
VALUES ('POINT (-77.088237 38.895701)', 10, 1, 1.0), ('POINT (-77.150693 38.892861)', 50, 1, 1.0), 
       ('POINT( -76.956383 39.071894)', 20, 2, 1.0), ('POINT (-77.069505 38.91801)', 30, 2, 1.0), ('POINT (-77.063653 38.908072)', 40, 2, 1.0);
select * from dc_demands;
/* SQL Block End */


/* SQL Block Start */
select IF(total_demands>=total_supplies,'SUPLLY MATCHES DEMAND','SUPPLY LESS THAN DEMAND') as kk from 
(select sum(size) as total_demands from dc_demands),
(select sum(size) as total_supplies from dc_supplies);
/* SQL Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH
                  dc ( EDGES => INPUT_TABLE(
                                           (SELECT id  AS ID,
                                                   wkt AS WKTLINE,
                                                   dir AS DIRECTION,
                                                   time  AS WEIGHT_VALUESPECIFIED                                                   
                                           FROM ki_home.dc))
                  );
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc_msdo;
EXECUTE FUNCTION
MATCH_GRAPH(
      GRAPH => 'ki_home.dc',
      SAMPLE_POINTS => INPUT_TABLES(
                               (SELECT id        AS DEMAND_ID,
                                       wkt       AS DEMAND_WKTPOINT,
                                       size      AS DEMAND_SIZE,
                                       supply_id AS DEMAND_DEPOT_ID
                                FROM ki_home.dc_demands
                               ),
                               (SELECT id       AS SUPPLY_DEPOT_ID,
                                       wkt      AS SUPPLY_WKTPOINT,
                                       truck_id AS SUPPLY_TRUCK_ID,
                                       size     AS SUPPLY_TRUCK_SIZE
                                FROM ki_home.dc_supplies
                               )
      ),
      SOLVE_METHOD   => 'match_supply_demand',
      SOLUTION_TABLE => 'ki_home.dc_msdo',
      OPTIONS => KV_PAIRS( output_tracks = 'false',
                           aggregated_output   = 'true'));
/* SQL Block End */


/* SQL Block Start */
select * from ki_home.dc_msdo;
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc_msdo_svg;
EXECUTE FUNCTION
MATCH_GRAPH(
      GRAPH => 'ki_home.dc',
      SAMPLE_POINTS => INPUT_TABLES(
                               (SELECT id        AS DEMAND_ID,
                                       wkt       AS DEMAND_WKTPOINT,
                                       size      AS DEMAND_SIZE,
                                       supply_id AS DEMAND_DEPOT_ID
                                FROM ki_home.dc_demands
                               ),
                               (SELECT id       AS SUPPLY_DEPOT_ID,
                                       wkt      AS SUPPLY_WKTPOINT,
                                       truck_id AS SUPPLY_TRUCK_ID,
                                       size     AS SUPPLY_TRUCK_SIZE
                                FROM ki_home.dc_supplies
                               )
      ),
      SOLVE_METHOD   => 'match_supply_demand',
      SOLUTION_TABLE => 'ki_home.dc_msdo_svg',
      OPTIONS => KV_PAIRS( output_tracks = 'true',
                           aggregated_output   = 'true',
                           svg_width = '400', svg_height = '600',  svg_speed = '100', svg_basemap = 'true', timeout = '60'));
/* SQL Block End */


/* SQL Block Start */
create or replace view dc_od_pairs as 
select dc_supplies.wkt as origin,  dc_demands.wkt as target, dc_supplies.id+dc_demands.id as id 
from dc_supplies cross join dc_demands;
select * from dc_od_pairs;
/* SQL Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS ki_home.dc_sssp;
EXECUTE FUNCTION
MATCH_GRAPH(
    GRAPH => 'ki_home.dc',
    SOLVE_METHOD => 'match_batch_solves',
    SAMPLE_POINTS => INPUT_TABLE ( SELECT 
                            origin AS SAMPLE_ORIGIN_WKTPOINT,
                            target AS SAMPLE_DESTINATION_WKTPOINT,
                            id     AS SAMPLE_OD_ID FROM ki_home.dc_od_pairs),
    SOLUTION_TABLE => 'ki_home.dc_sssp',
    OPTIONS => KV_PAIRS(output_tracks = 'true',
                           aggregated_output   = 'true',
                           svg_width = '400', svg_height = '600',  svg_speed = '20', svg_basemap = 'true', timeout = '60')
);
/* SQL Block End */

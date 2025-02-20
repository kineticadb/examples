/* Workbook: Foursquare OS Places */
/* Workbook Description: Analyzing Foursquare's Open Source Places Data */


/* Worksheet: Data Load (non Free SaaS) Copy */
/* Worksheet Description: Description for Sheet 1 */


/* SQL Block Start */
CREATE SCHEMA public;
/* SQL Block End */


/* SQL Block Start */
-- Data source for FSQ OSS Places
CREATE OR REPLACE DATA SOURCE public.fsq_oss_places
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'fsq-os-places-us-east-1',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* SQL Block Start */
-- Load FSQ OSS Places
LOAD DATA INTO public.fsq_places
FROM FILE PATHS 'release/dt=2025-02-06/places/parquet/'
 WITH OPTIONS (
    DATA SOURCE = 'public.fsq_oss_places',
    ON ERROR = PERMISSIVE
);
/* SQL Block End */


/* SQL Block Start */
-- Load FSQ OSS Place Categories
LOAD DATA INTO public.fsq_categories
FROM FILE PATHS 'release/dt=2025-02-06/categories/parquet/'
 WITH OPTIONS (
    DATA SOURCE = 'public.fsq_oss_places',
    ON ERROR = PERMISSIVE
);
/* SQL Block End */


/* SQL Block Start */
-- Data source for Seattle OSM road network
CREATE OR REPLACE DATA SOURCE public.seattle_osm_data
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* SQL Block Start */
-- Load Seattle OSM road network
LOAD DATA INTO public.seattle_roads
FROM FILE PATHS 'osm_seattle_metro_road_network_gfx.csv.gz'
FORMAT TEXT 
WITH OPTIONS(
    DATA SOURCE = 'public.seattle_osm_data'
);
/* SQL Block End */


/* SQL Block Start */
-- Create graph from Seattle OSM road network
CREATE OR REPLACE DIRECTED GRAPH public.osm_seattle_metro_road_network (
    EDGES => INPUT_TABLES(
        (SELECT 
            EDGE_ID,
            EDGE_WKTLINE,
            EDGE_DIRECTION,
            WEIGHTS_VALUESPECIFIED AS WEIGHT_VALUESPECIFIED
            FROM public.seattle_roads
        )
    ),
    OPTIONS => KV_PAIRS(merge_tolerance = '1.0e-4')
);
/* SQL Block End */


/* Worksheet: Data Exploration */
/* Worksheet Description: Run some queries and look at the data */


/* TEXT Block Start */
/*
Foursquare's Open Source Places data set is now available for commercial use under an Apache 2.0 license: https://location.foursquare.com/resources/blog/products/foursquare-open-source-places-a-new-foundational-dataset-for-the-geospatial-community/
With Kinetica we can easily explore and analyze large geospatial datasets like Foursquare Open Source Places.
Thanks to Kinetica's GPU accelerated server-side visalization, we can instantly view and analyze all 100 million worldwide places on a map!
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
With SQL and Kinetica's spatial and graph capabilites, we can further analyze the data.  Let's zoom in on a well known brand, like Starbucks.
*/
/* TEXT Block End */


/* SQL Block Start */
-- How many Starbucks places are in the data set?
SELECT COUNT(*) AS count FROM public.fsq_places 
WHERE STRING(fsq_category_labels) LIKE '%Cafe%' AND LOWER (name) LIKE '%starbucks%';
/* SQL Block End */


/* SQL Block Start */
-- Now we'll visualize the Starbucks locations by creating a materialized view and adding a Map Block
CREATE or REPLACE TEMP TABLE fsq_places_starbucks AS 
    SELECT geom FROM public.fsq_places 
    WHERE geom IS NOT NULL 
        AND STRING(fsq_category_labels) LIKE '%Cafe%' 
        AND LOWER (name) LIKE '%starbucks%';
/* SQL Block End */


/* SQL Block Start */
-- Zooming into Seattle, we can isolate the Starbucks within a bounding box for the greater Seattle region.
CREATE or REPLACE TEMP TABLE fsq_places_starbucks_seattle AS
    SELECT geom AS WKTPOINT from fsq_places_starbucks
    WHERE stxy_intersects(ST_X(geom), ST_Y(geom),
                            'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))');
/* SQL Block End */


/* Worksheet: Place Analysis with Travel Time */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
Kinetica's built in Graph engine supports graph-based analysis and algorithms through SQL.  By creating a graph from road network data (such as Open Street Map), we can analyze travel time to different places using Kinetica's built-in algorithms.
See the Graph Shortest Path sample workbook for more information on building and analyzing road network graphs in Kinetica.
You can try analyzing a different part of the US by building your own graph from the OSM road network.  Select Create Graph in the Data Object Explorer in the left hand pane, and then choose the OSM option.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
First, let's look at the OSM road network we have extracted for the greater Seattle region.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Using this road network graph, we can find all of the points that are within a 2 minute drive to a Starbucks.
Here's a single line of SQL to perform this isochrone analysis.
*/
/* TEXT Block End */


/* SQL Block Start */
/* 

This query calculates the area that is within a 2 minute driving distance from all Starbucks locations in the greater Seattle area.

The subquery selects all places from public.fsq_places that:
- Are within a bounding box defined by the polygon (stxy_intersects ensures only locations within Seattle metro).
- Have a category containing "Cafe".
- Have a name containing "Starbucks" (case insensitive).
- Have a location (geometry is not NULL)

For each of the places, we run Inverse Shortest Path Analysis:
- The SOLVE_GRAPH function computes inverse shortest paths on the public.osm_seattle_metro_road_network.  
- It finds areas reachable within a maximum radius of 120 seconds (max_solution_radius).
- The Starbucks locations are used as the source nodes for this analysis.

Generate a smoothed boundary (concave hull):
- The result of the graph solver provides point geometries (x, y coordinates).
- These points are collected into a single geometry (ST_collect_aggregate).
- A smoothed boundary (concave hull) is computed around these points with ST_concavehull(poly, 0.8), controlling how tightly the shape fits around the points.

Dissolve Overlapping Areas:
- The final step (ST_DISSOLVEOVERLAPPING) merges overlapping coverage areas into a single region.

*/

 SELECT ST_DISSOLVEOVERLAPPING(poly) as WKT
 FROM
 (SELECT ST_CONCAVEHULL(ST_collect_aggregate(ST_makePoint(x,y)),0.8) as poly
    FROM 
    SOLVE_GRAPH
    (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVER_TYPE => 'INVERSE_SHORTEST_PATH',     
      SOURCE_NODES => INPUT_TABLES(
           (SELECT geom AS WKTPOINT from public.fsq_places
           WHERE
                STXY_INTERSECTS(longitude,latitude,
                 'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
            AND STRING(fsq_category_labels) LIKE '%Cafe%' 
            AND LOWER(name) LIKE '%starbucks%'
            AND geom IS NOT NULL)
      ),              
      OPTIONS => KV_PAIRS(max_solution_radius = '120')
    )
    WHERE z < 120
    GROUP by SOURCE);
/* SQL Block End */


/* TEXT Block Start */
/*
Now we will create tables for next 7-Eleven and Peets Coffee so we can compare their respsective coverage areas.
*/
/* TEXT Block End */


/* SQL Block Start */
-- All in one SQL statement: Finding 2 min aggregated coverage for all 7-Eleven cafe shops in Seattle metro
create or replace table seveneleven_coverage as
 SELECT ST_DISSOLVEOVERLAPPING(poly) as WKT
 FROM
 (SELECT ST_concavehull(ST_collect_aggregate(ST_makePoint(x,y)),0.8) as poly
    FROM 
    SOLVE_GRAPH
    (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVER_TYPE => 'INVERSE_SHORTEST_PATH',     
      SOURCE_NODES => INPUT_TABLES(
           (SELECT geom AS WKTPOINT from public.fsq_places
           WHERE
                stxy_intersects(longitude,latitude,
                 'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
            AND LOWER(name) LIKE '%eleven%'
            AND geom IS NOT NULL)
      ),              
      OPTIONS => KV_PAIRS(max_solution_radius = '120')
    )
    WHERE z < 120
    GROUP by SOURCE);
/* SQL Block End */


/* SQL Block Start */
-- All in one SQL statement: Finding 2 min aggregated coverage for all Peets cafe shops in Seattle metro
-- The Visualization showing the superimposed coverages of all the 3 cafe shops within 2-minute reach in Seattle metro residences
create or replace table peets_coverage as
 SELECT ST_DISSOLVEOVERLAPPING(poly) as WKT
 FROM
 (SELECT ST_concavehull(ST_collect_aggregate(ST_makePoint(x,y)),0.8) as poly
    FROM 
    SOLVE_GRAPH
    (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVER_TYPE => 'INVERSE_SHORTEST_PATH',     
      SOURCE_NODES => INPUT_TABLES(
           (SELECT geom AS WKTPOINT from public.fsq_places
           WHERE
                stxy_intersects(longitude,latitude,
                 'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
            AND LOWER(name) LIKE '%peets%'
            AND geom IS NOT NULL)
      ),              
      OPTIONS => KV_PAIRS(max_solution_radius = '120')
    )
    WHERE z < 120
    GROUP by SOURCE);
/* SQL Block End */


/* Worksheet: Fire Station Coverage */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
Similarly, we can analyze the areas within the Seattle region that are within close proximity to a fire station.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Finding 4 min aggregated coverage for fire stations in Seattle metro
SELECT ST_DISSOLVEOVERLAPPING(poly) as WKT
 FROM
 (SELECT ST_CONCAVEHULL(ST_COLLECT_AGGREGATE(ST_MAKEPOINT(x,y)),0.8) as poly
    FROM 
    SOLVE_GRAPH
    (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVER_TYPE => 'SHORTEST_PATH',     
      SOURCE_NODES => INPUT_TABLES(
           (SELECT geom AS WKTPOINT from public.fsq_places
            WHERE
                  STXY_INTERSECTS(longitude,latitude,
                   'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
                AND
                  STRING(fsq_category_labels) LIKE '%Fire Station%'
           ) 
      ),
      OPTIONS => KV_PAIRS(max_solution_radius = '240')
    )
    WHERE z < 240
    GROUP by SOURCE);
/* SQL Block End */


/* TEXT Block Start */
/*
The pairwise batch solve for every station to go to one location used below - instead of running as many dijkstra solves for each station (origin), destination pair, which would be 500+ solves, we make use of the Kinetica's inverse solve  trademark  algorithm to revert road directions inside the solve, and hence doing it only one solve which gives the same results but in a fraction of time.
Using the option 'output_tracks' we demonstrate the simulation of the result as
SVG
file in the match/graph API response. After running below, there will be a button appearing as '
Animate
' - that would play the SVG content with the relevant options set below. (E.g.: svg_speed, svg_basemap, svg_height, svg_width, etc)  -
*/
/* TEXT Block End */


/* SQL Block Start */
-- Find the fastest fire stations to reach to a disaster x,y location among all available over seattle road network
-- Click on  
DROP TABLE IF EXISTS batch_sssp;
EXECUTE FUNCTION
MATCH_GRAPH(
GRAPH => 'public.osm_seattle_metro_road_network',
SAMPLE_POINTS => INPUT_TABLES(
   (SELECT ROW_NUMBER() OVER (PARTITION BY NULL ORDER BY fsq_place_id) AS OD_ID,
           ST_GEOMFROMTEXT('POINT(-121.958755 47.177694)') AS ORIGIN_WKTPOINT,
           geom AS DESTINATION_WKTPOINT
    FROM public.fsq_places
        WHERE  STXY_INTERSECTS(longitude,latitude,'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') AND
        STRING(fsq_category_labels) LIKE '%Fire Station%')
   ),
SOLVE_METHOD => 'match_batch_solves',
SOLUTION_TABLE => 'batch_sssp',
OPTIONS => KV_PAIRS(inverse_solve = 'true', output_tracks = 'true', svg_speed = '50', svg_basemap = 'true'));
/* SQL Block End */


/* SQL Block Start */
-- Create a look up table for hashed place_ids for the Fire Stations
CREATE OR REPLACE table hashing_map AS
 SELECT hash(fsq_place_id) AS hashed_id, fsq_place_id AS string_id FROM public.fsq_places 
   WHERE stxy_intersects(longitude,latitude,'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
   AND
   STRING(fsq_category_labels) LIKE '%Fire Station%';
   
-- Find fire station names that can reach to a x,y location in the minimum time among all available
WITH t AS (
    SELECT * from MATCH_GRAPH(
        GRAPH => 'public.osm_seattle_metro_road_network',
        SAMPLE_POINTS => INPUT_TABLES(
            (SELECT hash(fsq_place_id) AS  OD_ID, ST_geomFromText('POINT(-121.958755 47.177694)') AS ORIGIN_WKTPOINT, geom AS DESTINATION_WKTPOINT 
                FROM public.fsq_places
                WHERE  stxy_intersects(longitude,latitude,
                 'POLYGON ((-124.7228 47.03614, -121.16819 47.03614, -121.16819 48.578765, -124.72282 48.57876, -124.72282 47.03614))') 
                    AND
                    STRING(fsq_category_labels) LIKE '%Fire Station%')
            ),
        SOLVE_METHOD => 'match_batch_solves',
        OPTIONS => KV_PAIRS(inverse_solve = 'true')
    )
)
SELECT DISTINCT w.name, t.COST
FROM public.fsq_places AS w

INNER JOIN  hashing_map AS s 
ON w.fsq_place_id = s.string_id

INNER JOIN t
ON long(t.INDEX) = s.hashed_id
ORDER BY 2 asc;
/* SQL Block End */


/* Worksheet: Other examples */
/* Worksheet Description:  */


/* SQL Block Start */
-- All in one query: Find all groceries that are within the 10 min isochrones from the 10 random locations over the seattle road network
SELECT polys.SOURCE, places.name
FROM        
    MATCH_GRAPH (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVE_METHOD => 'match_isochrone',     
      SAMPLE_POINTS => INPUT_TABLES((SELECT 1 AS ID, ST_GEOMFROMTEXT('POINT(-122.303426 47.555293)') AS WKTPOINT), 
                                    (SELECT 2 AS ID, ST_GEOMFROMTEXT('POINT(-122.379273 47.515505)') AS WKTPOINT),
                                    (SELECT 3 AS ID, ST_GEOMFROMTEXT('POINT(-122.119785 47.358027)') AS WKTPOINT),
                                    (SELECT 4 AS ID, ST_GEOMFROMTEXT('POINT(-122.088521 47.978087)') AS WKTPOINT),
                                    (SELECT 5 AS ID, ST_GEOMFROMTEXT('POINT(-122.029158 47.991328)') AS WKTPOINT),
                                    (SELECT 6 AS ID, ST_GEOMFROMTEXT('POINT(-122.167888 48.093946)') AS WKTPOINT), 
                                    (SELECT 7 AS ID, ST_GEOMFROMTEXT('POINT(-122.258118 47.868229)') AS WKTPOINT), 
                                    (SELECT 8 AS ID, ST_GEOMFROMTEXT('POINT(-123.015029 47.444572)') AS WKTPOINT),                                    
                                    (SELECT 9 AS ID, ST_GEOMFROMTEXT('POINT(-123.414615 47.169875)') AS WKTPOINT),
                                    (SELECT 10 AS ID, ST_GEOMFROMTEXT('POINT(-121.958755 47.177694)') AS WKTPOINT)                                                                       
                        ),           
      OPTIONS => KV_PAIRS(      
      max_radius = '600', result_table_index = '2')
    ) AS polys
    INNER JOIN public.fsq_places AS places 
    ON STXY_INTERSECTS(places.longitude,places.latitude,polys.POLYGON) AND STRING(places.fsq_category_labels) LIKE '%Grocery%' ORDER BY SOURCE asc;
/* SQL Block End */


/* SQL Block Start */
-- Show the 10 min reachability polygons (isochrones) from 10 random locations
DROP TABLE IF EXISTS seattle_contours;
EXECUTE FUNCTION
    MATCH_GRAPH
    (GRAPH => 'public.osm_seattle_metro_road_network',
      SOLVE_METHOD => 'match_isochrone',     
      SAMPLE_POINTS => INPUT_TABLES((SELECT 1 AS ID, ST_GEOMFROMTEXT('POINT(-122.303426 47.555293)') AS WKTPOINT), 
                                    (SELECT 2 AS ID, ST_GEOMFROMTEXT('POINT(-122.379273 47.515505)') AS WKTPOINT),
                                    (SELECT 3 AS ID, ST_GEOMFROMTEXT('POINT(-122.119785 47.358027)') AS WKTPOINT),
                                    (SELECT 4 AS ID, ST_GEOMFROMTEXT('POINT(-122.088521 47.978087)') AS WKTPOINT),
                                    (SELECT 5 AS ID, ST_GEOMFROMTEXT('POINT(-122.029158 47.991328)') AS WKTPOINT),
                                    (SELECT 6 AS ID, ST_GEOMFROMTEXT('POINT(-122.167888 48.093946)') AS WKTPOINT), 
                                    (SELECT 7 AS ID, ST_GEOMFROMTEXT('POINT(-122.258118 47.868229)') AS WKTPOINT), 
                                    (SELECT 8 AS ID, ST_GEOMFROMTEXT('POINT(-123.015029 47.444572)') AS WKTPOINT),                                    
                                    (SELECT 9 AS ID, ST_GEOMFROMTEXT('POINT(-123.414615 47.169875)') AS WKTPOINT),
                                    (SELECT 10 AS ID, ST_GEOMFROMTEXT('POINT(-121.958755 47.177694)') AS WKTPOINT)                                                                       
                        ),      
      SOLUTION_TABLE => 'seattle_contours',
      OPTIONS => KV_PAIRS(      
      max_radius = '600', result_table_index = '2')
  );
/* SQL Block End */

-- Create the data source
CREATE OR REPLACE DATA SOURCE guides_data
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'guidesdatapublic',
    REGION = 'us-east-1'
);

-- Load data into a table in Kinetica
LOAD DATA INTO road_weights
FROM FILE PATHS 'road_weights.csv'
FORMAT TEXT 
WITH OPTIONS(
    DATA SOURCE = 'guides_data'
);

-- View the data
SELECT * 
FROM ki_home.road_weights
LIMIT 5;

-- Create the graph
CREATE OR REPLACE DIRECTED GRAPH GRAPH_S (
    EDGES => INPUT_TABLE(
        SELECT
            WKTLINE AS EDGE_WKTLINE,
            TwoWay AS EDGE_DIRECTION
        FROM
            ki_home.road_weights
    ),
    WEIGHTS => INPUT_TABLE(
        SELECT
            WKTLINE AS WEIGHTS_EDGE_WKTLINE,
            TwoWay AS WEIGHTS_EDGE_DIRECTION,
            time AS WEIGHTS_VALUESPECIFIED
        FROM
            ki_home.road_weights
    ),
    OPTIONS => KV_PAIRS(
        'recreate' = 'true',
        'enable_graph_draw' = 'true',
        'graph_table' = 'seattle_graph_debug'
    )
);

-- Create tables to record the source and destination points

CREATE OR REPLACE TABLE seattle_sources (wkt WKT NOT NULL);

INSERT INTO ki_home.seattle_sources 
VALUES ('POINT(-122.1792501 47.2113606)');

CREATE OR REPLACE TABLE seattle_dest (wkt WKT NOT NULL);

INSERT INTO ki_home.seattle_dest
VALUES ('POINT(-122.2221 47.5707)');

-- Execute the solve graph function
EXECUTE FUNCTION SOLVE_GRAPH(
    GRAPH => 'GRAPH_S',
    SOLVER_TYPE => 'SHORTEST_PATH',
    SOURCE_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_sources),
    DESTINATION_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_dest),
    SOLUTION_TABLE => 'GRAPH_S_ONE_ONE_SOLVED'
);

SELECT * FROM ki_home.GRAPH_S_ONE_ONE_SOLVED;

INSERT INTO ki_home.seattle_dest
VALUES
('POINT(-122.541017 47.809121)'), 
('POINT(-122.520440 47.624725)'),
('POINT(-122.467915 47.427280)');

EXECUTE FUNCTION SOLVE_GRAPH(
    GRAPH => 'GRAPH_S',
    SOLVER_TYPE => 'SHORTEST_PATH',
    SOURCE_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_sources),
    DESTINATION_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_dest),
    SOLUTION_TABLE => 'GRAPH_S_ONE_MANY_SOLVED'
);

select * from ki_home.GRAPH_S_ONE_MANY_SOLVED;

INSERT INTO ki_home.seattle_sources 
VALUES
('POINT(-122.1792501 47.2113606)'), 
('POINT(-122.375180125237 47.8122103214264)'),
('POINT(-122.375180125237 47.8122103214264)');

EXECUTE FUNCTION SOLVE_GRAPH(
    GRAPH => 'GRAPH_S',
    SOLVER_TYPE => 'SHORTEST_PATH',
    SOURCE_NODES => INPUT_TABLE((SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_sources)),
    DESTINATION_NODES => INPUT_TABLE((SELECT ST_GEOMFROMTEXT(wkt) AS NODE_WKTPOINT from seattle_dest)),
    SOLUTION_TABLE => 'GRAPH_S_MANY_MANY_SOLVED'
);

select * from ki_home.GRAPH_S_MANY_MANY_SOLVED;
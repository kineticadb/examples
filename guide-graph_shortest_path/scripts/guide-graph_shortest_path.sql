-- Create the data source
CREATE OR REPLACE DATA SOURCE guides_data
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'guidesdatapublic',
    REGION = 'us-east-1'
)

-- Load data into a table in Kinetica
LOAD DATA INTO road_weights
FROM FILE PATHS 'road_weights.csv'
FORMAT TEXT 
WITH OPTIONS(
    DATA SOURCE = 'guides_data'
)

-- View the data
SELECT * 
FROM ki_home.road_weights
LIMIT 5

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
)

-- Solve - One to one
EXECUTE FUNCTION SOLVE_GRAPH(
    GRAPH => 'GRAPH_S',
    SOLVER_TYPE => 'SHORTEST_PATH',
    SOURCE_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT('POINT(-122.1792501 47.2113606)') AS NODE_WKTPOINT),
    DESTINATION_NODES => INPUT_TABLE(SELECT ST_GEOMFROMTEXT('POINT(-122.2221 47.5707)') AS NODE_WKTPOINT),
    SOLUTION_TABLE => 'TABLE_GRAPH_S_SPSOLVED',
    OPTIONS => KV_PAIRS(
    'export_solve_results' = 'true'
  )
)
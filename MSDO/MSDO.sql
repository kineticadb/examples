/* Workbook: Multiple Supple Demand Optimization */
/* Workbook Description:  */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 3 */


/* TEXT Block Start */
/*
This SQL workbook showcases how to leverage Kinetica’s Multiple Supply Demand Optimization (MSDO) Graph Solver, a powerful tool designed for complex, routing optimization. The workbook walks you through a scenario involving 18 customers and 12 trucks with variable capacities, originating from 2 supply depots in the Washington DC area. Unlike traditional solvers, the MSDO solver considers a multitude of constraints, such as package volume, truck capacity, and even time penalties, to find the optimal route for each truck.
The workbook is divided into three main sections:
- Data setup, where we prepare the data sources, tables, and a graph representation of the Washington DC road network.
- Optimal route calculation using the MSDO solver and expalnation of options that can be used in a MSDO solver.
- Optimal route calculation using the MSDO solver's TSM(Travelling salesman mode) option.
HOW TO RUN?
All the steps and instructions are provided within the workbook itself.
To ensure successful execution of the workbook, it is essential to adhere to the prescribed order of blocks and sheets. We will create all the necessary data sources and download the required data into our workbook.
*/
/* TEXT Block End */


/* Worksheet: Data */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
CREATE THE DATA SOURCES
We will be using one data source for this example to retrieve data about our suppliers, customers, and spatial data that will be used to create road network graph that will be used in this workbook.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DATA SOURCE msdo_example
LOCATION = 'S3'
WITH OPTIONS (
    ANONYMOUS = 'true',
    BUCKET NAME = 'kinetica-examples-data-public',
    REGION = 'us-east-1'
);
/* SQL Block End */


/* TEXT Block Start */
/*
LOAD DATA
In the next step, we will load the spatial data, customers, and suppliers into tables.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS washington_dc_area;
LOAD DATA INTO washington_dc_area 
FROM FILE PATHS 'dc/dc_roads.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'msdo_example'
);

DROP TABLE IF EXISTS customers;
LOAD DATA INTO customers 
FROM FILE PATHS 'dc/demands_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'msdo_example'
);

DROP TABLE IF EXISTS suppliers;
LOAD DATA INTO suppliers 
FROM FILE PATHS 'dc/supplies_2.csv'
FORMAT TEXT 
WITH OPTIONS (
    DATA SOURCE = 'msdo_example'
);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE A GRAPH REPRESENTATION OF THE DC AREA ROAD NETWORK
The following block of code creates a graph of the road network in an around Washtington DC. To do this, first we need to load spatial data that represents the road network. This spatial data contains WKT lines for different road segments in DC along with the direction of travel and the time it takes to traverse that segment. When we create a graph using this road network data, under the hood Kinetica converts each spatial line representing a road segment into a directed edge with an associated weight. The weight in this case is the time for traversing that segment.
Kinetica uses a native representation for storing graph data. However, we can set an additional option in the create graph query that stores a relational representation of a graph object. In the query we have set that to washington_dc_area. We can use this table to visualize this graph on a map as shown below.
For more information on Kinetica's graph API please refer to the following playlist:
https://www.youtube.com/watch?v=wUpeZbzbK4Y&list=PLtLChx8K0ZZVkufn1GMvsR3BY2jMP3JXD
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE DIRECTED GRAPH dc 
    (EDGES => INPUT_TABLE (
        SELECT  id  AS ID,
            wkt AS WKTLINE,                                            
            dir AS DIRECTION,
            time  AS WEIGHT_VALUESPECIFIED
        FROM washington_dc_area),
        OPTIONS => KV_PAIRS
        ( 
            graph_table = 'dc_graph_table',
            add_turns = 'true'
        )
    );
/* SQL Block End */


/* Worksheet: MSDO */
/* Worksheet Description: Description for sheet 5 */


/* TEXT Block Start */
/*
HOW DOES A MSDO SOLVER WORK?
An MSDO solver takes the following inputs - a graph network, supply and demand points. It uses these to find the best routes between supply and demand points based on the constraints and costs associated with each of them.
- A demand point can have up to two constraints and a cost factor associated with it. In the current case one constraint is the total volume of packages at each customer location.
- A supply vehicle can have up to two constraints associated with it. In our case, each supply truck is constrained on the total volume it can carry.
SOLVER SPECIFICATION
For the "solve_method" section, we opt for "match_supply_demand," indicating that our solver will find the most optimized route in the MSDO concept. The output of the solver is stored in the "solution_table", which is set to the dc_msdo in the following query.
OPTIONAL PARAMETERS
The MSDO solver can also take a set of optional parameters. These include the following.
Left Turn Penalty:
Assigns a time penalty for each left turn made by the trucks.
Right Turn Penalty:
Assigns a time penalty for each right turn made by the trucks.
Intersection Penalty:
Assigns a time penalty for each truck that traverses intersections.
Sharp Turn Penalty:
Assigns a time penalty for each sharp turn made by the trucks.
Unit Unloading Cost:
Sets a cost of each unit load in the total trip cost. It becomes effective when the unit cost per load exceeds zero.
Enable Reuse:
Suppliers have the flexibility to complete round trips more than once, as needed, if this option is enabled as "true."
Service Limit:
Allows for the limitation of a suppliers total service cost, such as distance or time, by specifying a positive value. In this case, the cost limitation will be based on time(Seconds).
For more information on Kinetica's MSDO solver options please refer to the following link:
https://docs.kinetica.com/7.2/sql/graph/
Once the solver is run, an "Animate" button will appear at the end of the block. Note that the "output_tracks" parameter has to be set to "true" for this to work.
*/
/* TEXT Block End */


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
            FROM customers
        ),
        (
            SELECT 
                depot AS SUPPLY_DEPOT_ID,
                wkt AS SUPPLY_WKTPOINT,
                truck_id AS SUPPLY_TRUCK_ID,
                truck_size AS SUPPLY_TRUCK_SIZE
            FROM suppliers
        )
    ),
    SOLVE_METHOD   => 'match_supply_demand',
    SOLUTION_TABLE => 'dc_msdo',
    OPTIONS => KV_PAIRS
    ( 
        output_tracks = 'true',
        aggregated_output   = 'false',
        svg_width = '400', svg_height = '600',
        svg_speed = '500',svg_basemap = 'true', 
        timeout= '80',
        left_turn_penalty = '35',
        right_turn_penalty = '15',
        intersection_penalty = '40',
        sharp_turn_penalty = '10',
        unit_unloading_cost = '60'
        --enable_reuse = 'true',
        --service_limit = '12000'
    )
);
/* SQL Block End */


/* Worksheet: TSM Mode */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
WHAT IS BATCH TSM MODE?
The "BATCH_TSM_MODE" parameter operates with a specific focus, considering only one size attribute. Additionally, it imposes a constraint where the supplier can deliver only one unit of the package at a time to each customer location. Therefore, if a customer requires 4 units of packages, that customer will need to be visited 4 separate times to fulfill their requirement.
To illustrate this concept, we have an example in which our suppliers will become salesmen. Our salesmen will still have the same capacity to carry packages but will only be able to deliver one unit of a package to each customer location.
Our salesmen will be more flexible regarding size constraints, with their primary focus being to find the shortest path between customer locations. In our setup we have a total of 18 customers and 12 trucks in two zones. If we'd like to demo only one truck to do the deliveries in each zone, ie, dropping at each trip one unit (the way we can mimic using MSDO in TSM mode), then we set each customer load as one (could be more but then more trips would be needed), and each truck capaple of making the delivery to all, hence the capacity of 18. This is done just to demo the batch TSM use for MSDO solver.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP TABLE IF EXISTS dc_tsm_msdo;
EXECUTE FUNCTION MATCH_GRAPH
(
    GRAPH => 'dc',
    SOLVE_METHOD => 'match_supply_demand',
    SAMPLE_POINTS => INPUT_TABLES
    (
        (
            SELECT 
                id AS DEMAND_ID,
                wkt AS DEMAND_WKTPOINT,
                1 AS DEMAND_SIZE,
                depot AS DEMAND_DEPOT_ID
            FROM customers
        ),
        (
            SELECT 
                depot AS SUPPLY_DEPOT_ID,
                wkt AS SUPPLY_WKTPOINT,
                truck_id AS SUPPLY_TRUCK_ID,
                18 AS SUPPLY_TRUCK_SIZE
            FROM suppliers
        )
    ),
    SOLUTION_TABLE => 'dc_tsm_msdo',
    OPTIONS => KV_PAIRS
    ( 
        output_tracks = 'true',
        svg_width = '400', svg_height = '600',
        svg_speed = '10',svg_basemap = 'true', 
        timeout= '80',
        enable_reuse = 'true',
        batch_tsm_mode = 'true'
        
    )
);
/* SQL Block End */

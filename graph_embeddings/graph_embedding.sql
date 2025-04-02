/* Workbook: Graphs with Vector Embeddings */
/* Workbook Description: Demonstrates rectifying of the edge connections that are computed to be similar from vector embeddings into a graph that already has other rich set of (attributes) connections, allowing to run queries much more accurately than with only vector embeddings or  only graphs  */


/* Worksheet: Sheet 1 */
/* Worksheet Description: Description for Sheet 1 */


/* SQL Block Start */
-- Create a table with graph attributes along with a vector for movie preferences
CREATE OR REPLACE TABLE relations(name text, birth text, company text, school text, movie_likes vector(6));

-- vector representation for [horror,romantic,action,suspense,comedy,scifi]
INSERT INTO RELATIONS VALUES('kaan','turkey','kinetica','rpi','[0.7,0.0,0.5,0.8,0.3,1.0]');
INSERT INTO RELATIONS VALUES('tan', 'usa','ft','uva','[0.7,0.2,0.8,0.8,0.5,1.0]');
INSERT INTO RELATIONS VALUES('jony','usa','kinetica','penn','[0.3,0.2,0.5,0.6,0.4,0.8]');
INSERT INTO RELATIONS VALUES('samy','usa','kinetica','jh','[0.1,1.0,0.3,0.3,0.8,0.4]');
INSERT INTO RELATIONS VALUES('rony','india', 'kinetica', 'gm','[0.4,0.6,0.2,0.4,0.7,0.2]');
INSERT INTO RELATIONS VALUES('beny','india','simmetrix','rpi','[0.0,0.9,0.1,0.6,0.9,0.5]');
INSERT INTO RELATIONS VALUES('jimy','usa','apple','uva','[0.0,0.9,0.1,0.6,0.9,0.5]');
/* SQL Block End */


/* SQL Block Start */
-- Create the graph
CREATE OR REPLACE DIRECTED GRAPH netflix
(
   NODES => INPUT_TABLES(
       (SELECT name    AS NODE, 'PERSON'  AS LABEL FROM relations),
       (SELECT birth   AS NODE, 'COUNTRY' AS LABEL FROM relations),
       (SELECT company AS NODE, 'COMPANY' AS LABEL FROM relations),
       (SELECT school  AS NODE, 'SCHOOL'  AS LABEL FROM relations)
   ),
   EDGES => INPUT_TABLES(
       (SELECT name AS NODE1, birth   AS NODE2,  'BORN'      AS LABEL, float(1.0) AS WEIGHT_VALUESPECIFIED FROM relations),
       (SELECT name AS NODE1, company AS NODE2,  'WORKS'     AS LABEL, float(1.0) AS WEIGHT_VALUESPECIFIED FROM relations),
       (SELECT name AS NODE1, school  AS NODE2,  'GRADUATED' AS LABEL, float(1.0) AS WEIGHT_VALUESPECIFIED FROM relations),
       (
          SELECT 
             t1.name AS NODE1, t2.name AS NODE2, 'WATCHED'  AS LABEL,
             l2_distance(t1.movie_likes,t2.movie_likes)     AS WEIGHT_VALUESPECIFIED
          FROM  relations as t1
          CROSS JOIN relations AS t2 
          WHERE l2_distance(t1.movie_likes,t2.movie_likes) < 4*float(1.0/7.0) and STRCMP(t1.name, t2.name) = -1
       )
   ),
   OPTIONS => KV_PAIRS( graph_table = 'netflix_graph')
);
/* SQL Block End */


/* SQL Block Start */
-- Find schools related to kinetica's people whose connections are strongly based on other people's movie choices
-- MATCH (a:COMPANY { company :'kinetica') <- [:WORKS] <- (:PERSON) <- [:WATCHED] <- (:PERSON) -> [:GRADUATED] -> (d:SCHOOL)
DROP TABLE IF EXISTS netflix_query;
EXECUTE FUNCTION 
   QUERY_GRAPH(
     GRAPH => 'netflix',
     QUERIES => INPUT_TABLES(
       (SELECT 'kinetica' AS NODE),
       (SELECT -1 AS HOP_ID, 'PERSON'    AS NODE_LABEL),
       (SELECT -1 AS HOP_ID, 'WORKS'     AS EDGE_LABEL),
       (SELECT -2 AS HOP_ID, 'WATCHED'   AS EDGE_LABEL),
       (SELECT -2 AS HOP_ID, 'PERSON'    AS NODE_LABEL),
       (SELECT 3  AS HOP_ID, 'GRADUATED' AS EDGE_LABEL),
       (SELECT 3  AS HOP_ID, 'SCHOOL'    AS NODE_LABEL)              
     ),
     RINGS => 3,
     ADJACENCY_TABLE => 'netflix_query',
     OPTIONS => KV_PAIRS(use_cypher = 'true')
   );
/* SQL Block End */

/* Workbook: UDFs in Kinetica */
/* Workbook Description: A simple illustration of how to set up, manage and execute UDFs in Kinetica. */


/* Worksheet: Introduction */
/* Worksheet Description: Description for sheet 2 */


/* TEXT Block Start */
/*
In this workbook we will set up and execute a UDF that takes an input table and computes the sum of the squares of a column and returns an output table with the result.
SETUP (MUST COMPLETE BEFORE RUNNING THE REST OF THE CODE)
1. Go to the Files tab (left side explorer) and make a directory on kifs called 'udf' for the purposes of this example.
2. Download the file located here:  https://github.com/kineticadb/examples/blob/master/udf/udf_sos_proc.py
3. Upload the file above the 'udf' directory in KIFS

USER DEFINED FUNCTIONS
User-Defined Functions (UDFs) are custom functions created by users to perform operations that aren't covered by built-in functions within a database management system or programming environment. UDFs can serve to extend the functionality of SQL queries or to encapsulate complex logic into simpler function calls.
UDFS IN KINETICA
Kinetica provides support for User-Defined Function (UDF) creation and management in SQL. Unlike conventional UDFs, Kinetica UDFs are external programs that can be managed via SQL and may be run in distributed fashion across the cluster. This workbook will cover these features. The overall steps are as follows.
1. CREATE FUNCTION ENVIRONMENT: This creates a function environment for the UDF.
2. CREATE FUNCTION: Create the function by specifying the run command (python or java), its arguments, the location of the script, and optional parameters like the function environment.
3. EXECUTE FUNCTION: Execute the function by providing it input and output tables.
4. EXECUTE TABLE FUNCTION: This executes a UDTF (User Defined Table Function). A UDTF is simply a UDF defined to return a single table as its output
*/
/* TEXT Block End */


/* Worksheet: UDFs */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
CREATE AND ALTER FUNCTION ENVIRONMENT
This query creates the function environment for the python script. We can DESCRIBE the environment to see all the installed packages. ALTER FUNCTION ENVIRONMENT can be used to add new packages to the environment.
*/
/* TEXT Block End */


/* SQL Block Start */
/*Altering your environment with SQL */
CREATE FUNCTION ENVIRONMENT sos_py_environment;

-- Describe the environment to see the packages
DESCRIBE FUNCTION ENVIRONMENT sos_py_environment;
/* SQL Block End */


/* SQL Block Start */
-- Install the numpy package to the environment
ALTER FUNCTION ENVIRONMENT sos_py_environment INSTALL PYTHON PACKAGE 'numpy';

-- See the description with numpy added
DESCRIBE FUNCTION ENVIRONMENT sos_py_environment;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE AN INPUT TABLE
This is the table that we will use as the input to the UDF for calculating the sum of squares for the y1 column.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Make a simple input table
CREATE OR REPLACE TABLE sos_input (
    x1 int,
    y1 float  
);

-- Insert a few values into the table
INSERT INTO sos_input 
    (x1, y1) 
VALUES 
    (1, 1.0), 
    (2, 2.0), 
    (3, 3.0), 
    (4, 4.0), 
    (5, 5.0);
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE FUNCTION
The CREATE FUNCTION is defined as a UDTF - a UDF that returns a single output table. The RETURN TABLE clause specifies the DDL for this output tabke.  The mode is set as distributed. A distributed UDF procedure will be invoked within the database, executing in parallel against each data shard of the specified tables. When distributed, there will be one OS process per processing node in Kinetica.
For this to work, you will need to have the udf_sos_proc.py script in the 'udf' folder in kifs. See the Introduction tab for more instructions.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Create the function
CREATE OR REPLACE FUNCTION udf_sos_py_proc
RETURNS TABLE (id SMALLINT NOT NULL, y FLOAT)
MODE = 'distributed'
RUN_COMMAND = 'python'
RUN_COMMAND_ARGS = 'udf/udf_sos_proc.py'
FILE PATHS 'kifs://udf/udf_sos_proc.py'
WITH OPTIONS (SET_ENVIRONMENT = 'sos_py_environment');
/* SQL Block End */


/* TEXT Block Start */
/*
EXECUTE THE FUNCTION
An existing UDF/UDTF can be executed using the EXECUTE FUNCTION command. Additionally, a UDTF can be executed as a table function within a SELECT statement. Any user with the SYSTEM ADMIN permission or the EXECUTE FUNCTION permission on a specific UDF/UDTF (or across all UDFs/UDTFs) is allowed to execute it.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Execute function defining output table just by name to be created or appened to
EXECUTE FUNCTION udf_sos_py_proc /* KI_HINT_SAVE_UDF_STATS */
(
    INPUT_TABLE_NAMES => INPUT_TABLE(SELECT * FROM sos_input),
    OUTPUT_TABLE_NAMES => OUTPUT_TABLES('sos_output')
);

SELECT * FROM sos_output;
/* SQL Block End */


/* SQL Block Start */
-- Execute as a table function within a SELECT
SELECT * FROM TABLE 
(
    udf_sos_py_proc /* KI_HINT_SAVE_UDF_STATS */
    (
        INPUT_TABLE_NAMES => INPUT_TABLE(SELECT * FROM sos_input),
        OPTIONS => KV_PAIRS(run_tag = 'sum_of_squares')

    )   
);
/* SQL Block End */


/* SQL Block Start */
SHOW FUNCTION STATUS;
/* SQL Block End */


/* SQL Block Start */
DROP FUNCTION udf_sos_py_proc;
DROP FUNCTION ENVIRONMENT sos_py_environment;
/* SQL Block End */

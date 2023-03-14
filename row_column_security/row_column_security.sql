/* Workbook: Column Row Security IT setup */
/* Workbook Description: This guide workbook shows how to implement column and row security in Kinetica using SQL */


/* Worksheet: 1. Create Schema and Directory */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
NOTE: THIS ONLY WORKS ON DEVELOPER EDITION
This workbook showcases quereis that only an cluster admin can execute it therefore will not work on Kinetica's cloud offerings.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Create the schema
Schemas are logical containers for most database objects (tables, views, etc.). In order to place an object in a schema, the schema must be created first--schemas will not be automatically created when specified in CREATE TABLE or similar calls.
We will be using the schema OurCo to store all the employee and salary tables. The code below drops any existing occurrences of the OurCo schema. A schema can only be dropped if there are no tables in it. Setting the cascade option to true will drop the tables in a schema first and then drop the schema as well.
❗️ NOTE:
The drop schema command will remove any previously created tables with in the OurCo schema. You can either rename the schema or move the current tables to a different schema to prevent them from being lost.
You can read more about Schemas here: https://docs.kinetica.com/7.1/sql/ddl/#create-schema
*/
/* TEXT Block End */


/* SQL Block Start */
DROP SCHEMA IF EXISTS OurCo CASCADE;
CREATE SCHEMA OurCo;
/* SQL Block End */


/* TEXT Block Start */
/*
Create the employees table
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE OurCo.Employees
(
    first_name VARCHAR (32) NOT NULL,
    last_name VARCHAR (32) NOT NULL,
    user_id VARCHAR (32) NOT NULL, 
    ssn VARCHAR (16, primary_key) NOT NULL,
    dob DATE NOT NULL,
    address VARCHAR (64) NOT NULL,
    state   VARCHAR (64) NOT NULL,
    country VARCHAR (8) NOT NULL,
    employee_id SMALLINT (primary_key) NOT NULL,
    gender VARCHAR (16) NOT NULL,
    start_date DATE,
    end_date DATE,
    home_phone VARCHAR (32),
    cell_phone VARCHAR (32),
    title VARCHAR (32) NOT NULL,
    dept VARCHAR (32) NOT NULL,
    marital_status VARCHAR (16) NOT NULL,
    college VARCHAR (64),
    graduation_date DATE 
);
/* SQL Block End */


/* TEXT Block Start */
/*
Create salaries table
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE OurCo.Salaries 
(
    user_id VARCHAR (32, primary_key) NOT NULL,
    salary INTEGER
);
/* SQL Block End */


/* TEXT Block Start */
/*
Create the HR directory
Kinetica provides a file system interface that's packaged with every installation. The file system provides a repository for users to store and make use of files within the database.
The code below removes the HR directory if it exists. The recursive option removes any files within the directory.
*/
/* TEXT Block End */


/* SQL Block Start */
DROP DIRECTORY IF EXISTS 'HR'
WITH OPTIONS ('recursive' = 'true');

CREATE DIRECTORY 'HR';
/* SQL Block End */


/* Worksheet: 2. Create roles */
/* Worksheet Description: Create roles and grant them permissions */


/* TEXT Block Start */
/*
What is a role?
A role is a container for permissions. Once a role is created we can grant it permissions to access different tables, files and folders within Kinetica.
You can read more about role management here: https://docs.kinetica.com/7.1/sql/security/#role-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Create the human resources role
❗️ READ THIS: The SQL statement to create a role is only available for on-premise version of Kinetica. If you are Azure version of Kinetica, roles can only be created using the UI on workbench. Users on all versions of Kinetica can go to Manage > Users & Roles to create a new user human_resources on Azure. Alternatively, if you are on premise, then uncomment the code below to create the roles using SQL.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE ROLE human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
Create the engineering role
Follow the same steps as earlier to create the engineering role using the UI if you on Azure.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE ROLE engineering;
/* SQL Block End */


/* Worksheet: 3. Create Users and assign roles */
/* Worksheet Description: Create users and grant them different roles. */


/* TEXT Block Start */
/*
Create users
❗️ READ THIS: Use the UI, go to Manage > Users & Roles to create a new user "harry". Alternatively, if you on an on-premise version of Kinetica you, can uncomment the code below to create a new user via SQL.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE USER harry WITH password 'tempPass123!';
/* SQL Block End */


/* TEXT Block Start */
/*
Assign a role
Once a user is created we can grant them a role, which would automatically give them all the permissions associated with that role.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT human_resources TO harry;
/* SQL Block End */


/* TEXT Block Start */
/*
Follow the same steps as above to create a new user 'bjones' who belongs to engineering.
*/
/* TEXT Block End */


/* SQL Block Start */
-- CREATE USER bjones WITH password 'Engineer123!';
/* SQL Block End */


/* SQL Block Start */
GRANT engineering TO bjones;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 Task - Login as new users
1. Try logging out and logging back in using the newly created users harry
2. Once you log in you will notice that the schema OurCo or the HR folder that were created the "Create Schema and Directory" sheet are not present for these two users. This is because we haven't given them access yet. We will do so in the next sheet.
3. Repeat 1 & 2 for bjones
4. Log back in as the admin once you have tested the two users to grant permissions in the next sheet.
*/
/* TEXT Block End */


/* Worksheet: 4. Column and Row security */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
Grant permissions to a role
A role needs to be granted permissions to tables in an entire schema. We want the human resources team to have full access to the OurCo schema.
You can read more about managing permissions (privileges) here: https://docs.kinetica.com/7.1/sql/security/#privilege-management
*/
/* TEXT Block End */


/* SQL Block Start */
-- Grants full permissions to the OurCo schema and all the tables in it
GRANT ALL ON OurCo TO human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
Next let's grant the human_resources role write access to the HR folder so that they can upload csv files for employees and salaries.
*/
/* TEXT Block End */


/* SQL Block Start */
-- Grants write access to the HR folder on KiFS
GRANT WRITE ON HR TO human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 Task: Log in as harry and load the csv files into tables in Kinetica
1. Log in as harry who belongs to HR
2. Load the CSV files into HR folder: Now that you the HR role has full access to the HR folder, you can use that to upload the the employees.csv file and the salaries.csv file. Go ahead and do that.
3. Once the files are in the HR folder they can be loaded into a OurCo.Employees and OurCo.Salaries tables that were defined in the first sheet. Use the import wizard to do that.
4. Log back in as admin
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
Column security

We want the engineering team to only access the first name, last name, a hash of the cell phone and the last 4 digits of the SSN. We do this with a GRANT statement that picks which columns a role can see. The HASH and MASK functions are a handy way to obfuscate or hide sensitive information.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT SELECT ON TABLE OurCo.Employees (first_name, last_name, HASH(cell_phone), MASK(ssn, 1, 7, '*')) to engineering;
/* SQL Block End */


/* TEXT Block Start */
/*
Row Security
We can also use WHERE clauses to restrict the rows that a user can see. For instance, you can restrict access to salary by setting the user id to who ever is the current user. This would only show the rows where the user id in the salaries table corresponds to the username of the current user.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT SELECT ON TABLE OurCo.Salaries TO engineering WHERE user_id = CURRENT_USER();
/* SQL Block End */


/* TEXT Block Start */
/*
We can perform a quick gut check using the SHOW SECURITY statement to make sure the permissions have been assigned correctly.
*/
/* TEXT Block End */


/* SQL Block Start */
SHOW SECURITY FOR harry;
/* SQL Block End */


/* SQL Block Start */
SHOW SECURITY FOR bjones;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 Task - Log in as bjones to test column and row security
You should be able to see the employees and salaries tables. Confirm that you only able to see the columns you have permissions for and the salary row that corresponds to you.
*/
/* TEXT Block End */


/* Worksheet: 5. 🧹 - Clean up */
/* Worksheet Description: Description for sheet 5 */


/* SQL Block Start */
DROP SCHEMA IF EXISTS OurCo CASCADE;
/* SQL Block End */


/* SQL Block Start */
DROP DIRECTORY IF EXISTS 'HR'
WITH OPTIONS ('recursive' = 'true');
/* SQL Block End */

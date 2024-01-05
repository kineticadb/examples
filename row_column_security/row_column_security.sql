/* Workbook: Column Row Security IT Setup */
/* Workbook Description: This guide workbook shows how to implement column and row security in Kinetica using SQL */


/* Worksheet: 0. Introduction */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
❗️NOTE: THIS ONLY WORKS ON DEVELOPER EDITION.
This workbook showcases queries that only a cluster admin can execute; therefore, it will not work on Kinetica's cloud offerings.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
HOW TO PROVIDE DATA SECURITY IN AN ORGANIZAGTION?
This SQL workbook showcases how to provide data security within an organization using Kinetica. The workbook walks you through a scenario involving a company called 'OurCo' and we create roles and assign our users (employees) into these roles. Each role is strategically configured with specific permissions, ensuring that users only access relevant data crucial to their responsibilities. Leveraging Kinetica's table security features, unnecessary data is safeguarded from unauthorized access.
The workbook is divided into four main sections:
- Data setup, where we prepare and populate our tables.
- Creating roles for our organization.
-Creating users and assigning them to their respective roles.
- Granting permissions to each roles, guaranteeing controlled and secure data access.
HOW TO RUN?
All the steps and instructions are provided within the workbook itself.
To ensure successful execution of the workbook, it is essential to adhere to the prescribed order of blocks and sheets. We will create all the necessary data sources and download the required data into our workbook. When prompted in the workbook, log out from the admin account and sign in as other users to test security functionalities.
*/
/* TEXT Block End */


/* Worksheet: 1. Create Schema and Directory */
/* Worksheet Description: Description for Sheet 1 */


/* TEXT Block Start */
/*
WHAT IS A SCHEMA?
Schemas are logical containers for most database objects (tables, views, indexes, etc.), grouped together under a common name. In order to place an object in a schema, the schema must be created first—schemas will not be automatically created when specified in CREATE TABLE or similar calls.
CREATE A NEW SCHEMA
We will be creating a new schema called 'OurCo' to store all the employee and salary tables. Before we start creating the schema, we need to make sure there is no schema in our database with the same name.
The code below drops any existing occurrences of the OurCo schema. A schema can only be dropped if there are no tables in it. Setting the 'CASCADE' option to true will drop the tables in a schema first and then drop the schema as well.
❗️ NOTE:
The drop schema command will remove any previously created tables with in the OurCo schema. You can either rename the schema or move the current tables to a different schema to prevent them from being lost.
You can read more about Schemas here:
https://docs.kinetica.com/7.1/sql/ddl/#create-schema
*/
/* TEXT Block End */


/* SQL Block Start */
DROP SCHEMA IF EXISTS OurCo CASCADE;
CREATE SCHEMA OurCo;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE EMPLOYEES TABLE
Once we have created 'OurCo' schema, it is time to create the 'employees' table. The 'employees' table will store information about employees who work in our organization.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE OurCo.employees (
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
    cell_phone VARCHAR (32),
    title VARCHAR (32) NOT NULL,
    dept VARCHAR (32) NOT NULL,
    marital_status VARCHAR (16) NOT NULL,
    graduation_date DATE 
);
/* SQL Block End */


/* TEXT Block Start */
/*
POPULATE THE EMPLOYEES TABLE
Once we have created the 'employees' table, it is time to populate the table with employee information. Since we have 7 employees in our organization, we will insert information for all 7 employees.
*/
/* TEXT Block End */


/* SQL Block Start */
INSERT INTO OurCo.employees 
(first_name, last_name, user_id, ssn, dob, address, state, country, employee_id, gender, start_date, end_date, cell_phone, title, dept, marital_status, graduation_date)
VALUES
    ('Alice', 'Smith', 'alice.smith', '123-45-6789', '1990-05-15', '123 Main St', 'CA', 'USA', 101, 'Female', '2020-01-15', NULL, '555-5678-8878', 'Software Engineer', 'IT', 'Single', '2015-05-20'),
    ('Harry', 'Johnson', 'harry.johnson', '987-65-4321', '1988-03-22', '456 Oak St', 'NY', 'USA', 102, 'Male', '2019-02-10', NULL, '555-4321-9989', 'Marketing Specialist', 'Marketing', 'Married', '2014-12-15'),
    ('Charlie', 'Williams', 'charlie.williams', '456-78-9012', '1995-08-10', '789 Pine St', 'TX', 'USA', 103, 'Male', '2022-03-05', NULL, '555-8765-9987', 'HR Coordinator', 'Human Resources', 'Single',  '2018-06-30'),
    ('Diana', 'Davis', 'diana.davis', '789-01-2345', '1987-11-05', '987 Cedar St', 'FL', 'USA', 104, 'Female', '2018-10-15', NULL, '555-7654-1232', 'Financial Analyst', 'Finance', 'Married', '2013-08-25'),
    ('Bjones', 'Wilson', 'bjones.wilson', '234-56-7890', '1993-04-18', '543 Elm St', 'CA', 'USA', 105, 'Male', '2021-07-20', NULL, '555-6543-2232', 'Product Manager', 'Product Management', 'Single', '2017-09-12'),
    ('Fiona', 'Miller', 'fiona.miller', '567-89-0123', '1991-09-30', '654 Maple St', 'WA', 'USA', 106, 'Female', '2017-12-10', NULL, '555-5432-2321', 'Systems Analyst', 'IT', 'Married',  '2016-05-18'),
    ('George', 'Taylor', 'george.taylor', '890-12-3456', '1989-02-25', '876 Birch St', 'IL', 'USA', 107, 'Male', '2016-05-05', NULL, '555-4321-1912', 'Marketing Manager', 'Marketing', 'Single', '2012-11-30');
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE SALARIES TABLE
Now, it is time to create the 'salaries' table, which will store employee's salary information.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE OR REPLACE TABLE OurCo.salaries 
(
    user_id VARCHAR (32, primary_key) NOT NULL,
    salary INTEGER
);
/* SQL Block End */


/* TEXT Block Start */
/*
POPULATE SALARIES TABLE
Once we have created the 'salaries' table, it is time to populate the table with employee's salary information.
*/
/* TEXT Block End */


/* SQL Block Start */
INSERT INTO OurCo.salaries (user_id, salary)
VALUES
    ('alice.smith', 80000),
    ('harry.johnson', 85000),
    ('charlie.williams', 75000),
    ('diana.davis', 90000),
    ('bjones.wilson', 95000),
    ('fiona.miller', 82000),
    ('george.taylor', 88000);
/* SQL Block End */


/* Worksheet: 2. Create roles */
/* Worksheet Description: Create roles and grant them permissions */


/* TEXT Block Start */
/*
WHAT IS A ROLE?
A role is a container for permissions. It simplifies the process of managing access control by grouping related permissions together.
Roles are particularly useful in scenarios where multiple users need similar levels of access to various database objects, such as tables, files and folders within Kinetica.
You can read more about role management here:
https://docs.kinetica.com/7.1/sql/security/#role-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE THE HUMAN RESOURCES ROLE
The first role in our organization will be Human Resources. The following command will create the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE ROLE human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE ENGINEERING ROLE
After establishing the 'human_resources' role, proceed to create the second role, 'engineering,' with the following command.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE ROLE engineering;
/* SQL Block End */


/* Worksheet: 3. Create Users and assign roles */
/* Worksheet Description: Create users and grant them different roles. */


/* TEXT Block Start */
/*
WHAT IS A USER?
A user is an account that can connect to a database and perform operations, such as querying, modifying data, and executing stored procedures. Users are associated with specific permissions and access rights, defining their level of interaction with the database.
For now, we will assign only two of our employees to user accounts. These employees are Harry and Bjones. Harry will be assigned to the Human Resources role, and Bjones will be assigned to the Engineering role.
You can read more about user management here:
https://docs.kinetica.com/7.1/sql/security/#user-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE A NEW USER ACCOUNT FOR HARRY
The first step will be creating an account for Harry with a password.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE USER harry WITH password 'tempPass123!';
/* SQL Block End */


/* TEXT Block Start */
/*
ASSIGN A ROLE
Once we have created a user account for Harry, we can now grant a role to him. His account will automatically have all the permissions associated with the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT human_resources TO harry;
/* SQL Block End */


/* TEXT Block Start */
/*
REPEAT SAME STPES
We will follow the same steps as above to create a new user for Bjones and grant him the 'engineering' role.
*/
/* TEXT Block End */


/* SQL Block Start */
CREATE USER bjones IDENTIFIED BY 'Engineer123!';
/* SQL Block End */


/* SQL Block Start */
GRANT engineering TO bjones;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 TASK - LOGIN AS NEW USERS
1. Try logging out and logging back in using the newly created users harry.
2. Once you log in you will notice that the schema OurCo or the HR folder that were created the "Create Schema and Directory" sheet are not present for these two users. This is because we haven't given them access yet. We will do so in the next sheet.
3. Repeat 1 & 2 for bjones.
4. Log back in as the admin once you have tested the two users to grant permissions in the next sheet.
❗️ NOTE:
To ensure you are logged into the right account, you can run the command below to see which account you are currently accessing.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT CURRENT_USER() AS whoami;
/* SQL Block End */


/* Worksheet: 4. Column and Row security */
/* Worksheet Description: Description for sheet 4 */


/* TEXT Block Start */
/*
GRANTING PERMISSIONS TO A ROLE
In Kinetica, granting permissions to a role involves assigning specific privileges to the role so that any user assigned to that role inherits those permissions. This simplifies access management, as changes to permissions can be made at the role level rather than for each individual user.
You can read more about managing permissions (privileges) here:
https://docs.kinetica.com/7.1/sql/security/#privilege-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
GRANT FULL PERMISSIONS TO HUMAN RESOURCES
We want the Human Resources team to have full access to the OurCo schema so that they can access all the required information about our employees.
The following SQL command will grant full permissions to the OurCo schema and all the tables in it to the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT ALL ON OurCo TO human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
GRANT ACCESS TO THE HR FOLDER
Next let's grant the 'human_resources' role write access to the HR folder so that they can upload csv files for employees and salaries.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT WRITE ON HR TO human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 TASK: LOG IN AS HARRY AND LOAD THE CSV FILE INTO TABLES IN KINETICA
1. Log in as harry who belongs to HR.
2. Load the CSV files into HR folder: Now that you the HR role has full access to the HR folder, you can use that to upload the the employees.csv file and the salaries.csv file. Go ahead and do that.
3. Once the files are in the HR folder they can be loaded into a OurCo.Employees and OurCo.Salaries tables that were defined in the first sheet. Use the import wizard to do that.
4. Log back in as admin.
❗️ NOTE:
To ensure you are logged into the right account, you can run the command below to see which account you are currently accessing.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT CURRENT_USER() AS whoami;
/* SQL Block End */


/* TEXT Block Start */
/*
COLUMN SECURITY FOR ENGINEERING
We want the Engineering team to only access the first name, last name, a hash of the cell phone, and the last 4 digits of the SSN. To achieve these security goals, we can use 'HASH' and 'MASK' functions. In Kinetica, these functions are a handy way to obfuscate or hide sensitive information.
WHAT IS HASH FUNCTION?
In Kinetica, a hash function is a mathematical algorithm that transforms input data into a fixed-size string of characters, typically a hash code.
WHAT IS MASK FUNCTION?
In Kinetica, a mask function is a mechanism that helps conceal sensitive data during query results by transforming it into a masked format.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT SELECT ON TABLE OurCo.Employees (first_name, last_name, HASH(cell_phone), MASK(ssn, 1, 7, '*')) to engineering;
/* SQL Block End */


/* TEXT Block Start */
/*
ROW SECURITY
We can also use WHERE clauses to restrict the rows that a user can see. For instance, you can restrict access to salary by setting the user id to who ever is the current user. This would only show the rows where the user id in the salaries table corresponds to the username of the current user.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT SELECT ON TABLE OurCo.Salaries TO engineering WHERE user_id = CURRENT_USER();
/* SQL Block End */


/* TEXT Block Start */
/*
CHECK PERMISSIONS
We can perform a quick gut check using the "SHOW SECURITY" statement to make sure the permissions have been assigned correctly.
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
🎯 TASK - LOG IN AS BJONES TO TEST COLUMN AND ROW SECURITY
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


/* SQL Block Start */
DROP USER bjones;
DROP USER harry;
DROP ROLE human_resources;
DROP ROLE engineering;
/* SQL Block End */

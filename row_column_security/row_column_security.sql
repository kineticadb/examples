/* Workbook: Column Row Security IT Setup */
/* Workbook Description: This guide workbook shows how to implement column and row security in Kinetica using SQL */


/* Worksheet: 0. Introduction */
/* Worksheet Description: Description for sheet 6 */


/* TEXT Block Start */
/*
❗️NOTE: THIS ONLY WORKS ON DEVELOPER EDITION.
This workbook showcases queries that only a cluster admin can execute; therefore, it will not work on Kinetica's cloud offerings.
❗️NOTE: MAKE SURE AUTHORIZATION IS ENABLED.
This workbook requires the authorization setting to be set to true to demonstrate the security mechanism in Kinetica. Please follow the steps below to ensure that authorization is enabled.
- Log in to GAdmin (
http://localhost:8080/gadmin
) with your admin credentials.
- Click 'Admin' on the right-hand side and then click 'Stop' to shut down the database.
- Click 'Config' on the right-hand side and choose the 'Advanced' tab.
- Locate the parameter for authorization, which is 'enable_authorization,' and ensure it is set to 'true.'
- If it is not set to 'true,' update the value to 'true' and click the 'Update' button in the bottom right corner, then click 'Save & Restart.'
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
HOW TO PROVIDE DATA SECURITY IN AN ORGANIZAGTION?
This SQL workbook showcases how to provide data security within an organization using Kinetica. The workbook walks you through a scenario involving a company called 'OurCo' and we create roles and assign our users (employees) into these roles. Each role is strategically configured with specific permissions, ensuring that users only access relevant data crucial to their responsibilities. Leveraging Kinetica's table security features, unnecessary data is safeguarded from unauthorized access.
The workbook is divided into four main sections:
- Data setup, where we prepare and populate our tables.
- Creating roles for our organization.
- Creating users and assigning them to their respective roles.
- Granting permissions to each roles, guaranteeing controlled and secure data access.
HOW TO RUN?
All the steps and instructions are provided within the workbook itself.
To ensure successful execution of the workbook, it is essential to adhere to the prescribed order of blocks and sheets. We will create all the necessary data sources and download the required data into our workbook. When prompted in the workbook, log out from the admin account and sign in as other users to test security functionalities.
*/
/* TEXT Block End */


/* Worksheet: 1. Create Schema */
/* Worksheet Description: Description for Sheet 1 */


/* SQL Block Start */
DROP SCHEMA IF EXISTS OurCo CASCADE;
CREATE SCHEMA OurCo;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE EMPLOYEES TABLE
Once we have created the 'OurCo' schema, it is time to create the 'employees' table. The 'employees' table will store information about employees who work in our organization.
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
After creating the 'employees' table, the next step is to populate it with employee information. Since our organization has seven employees, we will now insert information for each of them.
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
    ('asmith', 80000), ('hjohnson', 85000),
    ('cwilliams', 75000), ('ddavis', 90000),
    ('bwilson', 95000), ('fmiller', 82000), ('gtaylor', 88000);
/* SQL Block End */


/* Worksheet: 2. Create Roles & Grant Permissions */
/* Worksheet Description: Create roles and grant them permissions */


/* TEXT Block Start */
/*
WHAT IS A ROLE?
A role is a container for permissions. It simplifies the process of managing access control by grouping related permissions together.
Roles are particularly useful in scenarios where multiple users need similar levels of access to various database objects, such as tables, files and folders within Kinetica.
You can read more about role management here:
https://docs.kinetica.com/7.2/sql/security/#role-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE THE HUMAN RESOURCES ROLE
The first role in our organization will be Human Resources. The following command will create the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
-- If the role has already been created, you can run the query below to drop the role.
-- DROP ROLE human_resources;

CREATE ROLE human_resources;
/* SQL Block End */


/* TEXT Block Start */
/*
CREATE THE ENGINEERING ROLE
After establishing the 'human_resources' role, proceed to create the second role, 'engineering,' with the following command.
*/
/* TEXT Block End */


/* SQL Block Start */
-- If the role has already been created, you can run the query below to drop the role.
-- DROP ROLE engineering;

CREATE ROLE engineering;
/* SQL Block End */


/* TEXT Block Start */
/*
GRANTING PERMISSIONS TO A ROLE
Once roles have been created in our organization, it is time to grant permissions to each role based on their associated tasks
HOW IT WORKS?
In Kinetica, granting permissions to a role involves assigning specific privileges to the role so that any user assigned to that role inherits those permissions. This simplifies access management, as changes to permissions can be made at the role level rather than for each individual user.
You can read more about managing permissions (privileges) here:
https://docs.kinetica.com/7.2/sql/security/#privilege-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
COLUMN SECURITY FOR HUMAN RESOURCES
We want the Human Resources team to have full access to the OurCo schema so that they can access all the required information about our employees.
The following SQL command will grant full permissions to the OurCo schema and all the tables in it to the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT ALL ON OurCo TO human_resources;
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
ROW SECURITY FOR ENGINEERING
We can also use WHERE clauses to restrict the rows that a user can see. For instance, you can restrict access to salary by setting the user id to who ever is the current user. This would only show the rows where the user id in the salaries table corresponds to the username of the current user.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT SELECT ON TABLE OurCo.Salaries TO engineering WHERE user_id = CURRENT_USER();
/* SQL Block End */


/* Worksheet: 3. Create Users & Assign Roles */
/* Worksheet Description: Create users and grant them different roles. */


/* TEXT Block Start */
/*
WHAT IS A USER?
A user is an account that can connect to a database and perform operations, such as querying, modifying data, and executing stored procedures. Users are associated with specific permissions and access rights, defining their level of interaction with the database.
For now, we will assign only two of our employees to user accounts. These employees are Harry and Bjones. Harry will be assigned to the Human Resources role, and Bjones will be assigned to the Engineering role.
You can read more about user management here:
https://docs.kinetica.com/7.2/sql/security/#user-management
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
CREATE A NEW USER ACCOUNT FOR HARRY
The first step will be creating an account for Harry with a password.
*/
/* TEXT Block End */


/* SQL Block Start */
-- If the user has already been created, you can run the query below to drop the user.
-- DROP USER hjohnson;

CREATE USER hjohnson WITH password 'tempPass123!';
/* SQL Block End */


/* TEXT Block Start */
/*
ASSIGN A ROLE
Once we have created a user account for Harry, we can now grant a role to him. His account will automatically have all the permissions associated with the 'human_resources' role.
*/
/* TEXT Block End */


/* SQL Block Start */
GRANT human_resources TO hjohnson;
/* SQL Block End */


/* TEXT Block Start */
/*
REPEAT SAME STPES FOR BJONES
We will follow the same steps as above to create a new user for Bjones and grant him the 'engineering' role.
*/
/* TEXT Block End */


/* SQL Block Start */
-- If the user has already been created, you can run the query below to drop the user.
-- DROP USER bwilson;

CREATE USER bwilson IDENTIFIED BY 'Engineer123!';
/* SQL Block End */


/* SQL Block Start */
GRANT engineering TO bwilson;
/* SQL Block End */


/* Worksheet: 4. Test Column & Row Security */
/* Worksheet Description: Description for sheet 7 */


/* TEXT Block Start */
/*
CHECK PERMISSIONS
We can perform a quick verification using the 'SHOW SECURITY' statement to ensure that permissions have been assigned correctly.
*/
/* TEXT Block End */


/* SQL Block Start */
SHOW SECURITY FOR hjohnson;
/* SQL Block End */


/* TEXT Block Start */
/*
Since we allowed the 'human resources' role to access all the data in the 'employees' and 'salaries' tables, there should not be any filter for Harry's user account.
*/
/* TEXT Block End */


/* SQL Block Start */
SHOW SECURITY FOR bwilson;
/* SQL Block End */


/* TEXT Block Start */
/*
TIME TO TEST
After verifying permissions and completing all previous steps to implement column and row security for our organization, the next step is to test some security functionalities.
*/
/* TEXT Block End */


/* TEXT Block Start */
/*
🎯 TASK - LOG IN AS HARRY TO TEST COLUMN AND ROW SECURITY
We should be able to see the employees and salaries tables. Since Harry is working in Human Resources Department, he needs to access all information about employees in the employees and salaries tables.
Confirm that you are able to see all columns and rows in employees and salaries tables.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT * FROM OurCo.employees;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM OurCo.salaries;
/* SQL Block End */


/* TEXT Block Start */
/*
🎯 TASK - LOG IN AS BJONES TO TEST COLUMN AND ROW SECURITY
We should be able to access the employees' and salaries' tables. Since Bjones works in the Engineering Department, he should not have visibility into sensitive information about other employees, such as SSN. Additionally, he should only be able to view his own salary and not the salaries of other employees.
Confirm that you can only see first names, last names, cell phones in hashed format, and only the last 4 digits of SSNs in the employees' table. In the salaries' table, only Bjones's salary should be accessible.
*/
/* TEXT Block End */


/* SQL Block Start */
SELECT * FROM OurCo.employees;
/* SQL Block End */


/* SQL Block Start */
SELECT * FROM OurCo.salaries;
/* SQL Block End */

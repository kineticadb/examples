<!---
version: 7.1.4
--->

# Security with Kinetica
## Demo video
[![Column row security in Kinetica](https://img.youtube.com/vi/XopOOMaruuU/0.jpg)](https://www.youtube.com/watch?v=XopOOMaruuU)


## Introduction
Database administers often need to restrict access to particular fields in your data based on who is accessing a table. For instance, you might want a customer service representative to only see the last 4 digits of sensitive information like say a credit card number. Or you might want to restrict access to salaries of employees to members of the HR department. Tasks like these require you to obfuscate, mask, or restrict access to certain rows and columns of your data.

This guide walks you through the basics of implementing row and column level security using role based access controls using the fictional example of a company called OurCo.

Watch the demo video above for a full walkthrough for this guide.

## To get started immediately
If you already have an instance of Kinetica, then you can simply upload the json file for the workbook (row_column_security.json) that is available. The demo, shows you how to implement security using both SQL and the UI. The workbook will show you how to do that with just some easy SQL code.

## Create the schema and directory
[Schemas](https://docs.kinetica.com/7.1/sql/ddl/#create-schema) are logical containers for most database objects (tables, views, etc.). In order to place an object in a schema, the schema must be created first--schemas will not be automatically created when specified in CREATE TABLE or similar calls.


### Create the OurCo schema
We will be using the schema OurCo to store all the employee and salary tables.

The code below drops any existing occurrences of the OurCo schema. A schema can only be dropped if there are no tables in it. Setting the cascade option to true will drop the tables in a schema first and then drop the schema as well.
❗️ NOTE:
The drop schema command will remove any previously created tables with in the OurCo schema. You can either rename the schema or move the current tables to a different schema to prevent them from being lost.

```sql
DROP SCHEMA if exists OurCo cascade;
CREATE SCHEMA OurCo;
```

### Create the employees table

```sql
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
```

### Create the salaries table
```sql
CREATE OR REPLACE TABLE OurCo.Salaries 
(
    user_id VARCHAR (32, primary_key) NOT NULL,
    salary INTEGER
);
```

### Create the HR directory
Kinetica provides a file system interface that's packaged with every installation. The file system provides a repository for users to store and make use of files within the database.
The code below removes the HR directory if it exists. The recursive option removes any files within the directory.

```sql
DROP DIRECTORY IF EXISTS 'HR'
WITH OPTIONS ('recursive' = 'true');

CREATE DIRECTORY 'HR';
```

## Create roles
### What is a role?
A [role](https://docs.kinetica.com/7.1/sql/security/#role-management) is a container for permissions. Once a role is created we can grant it permissions to access different tables, files and folders within Kinetica.

### Create the human resources role
The SQL statement to create a role is only available for on-premise version of Kinetica. If you are Azure version of Kinetica, roles can only be created using the UI on workbench. Users on all versions of Kinetica can go to Manage > Users & Roles to create a new user human_resources on Azure. Alternatively, if you are on premise, then uncomment the code below to create the roles using SQL.

```sql
-- CREATE ROLE human_resources;
```
### Create the engineering role
Follow the same steps as earlier to create the engineering role using the UI if you on Azure.

```sql
-- CREATE ROLE engineering;
```

## Create Users and assign roles
### Create users
Use the UI, go to Manage > Users & Roles to create a new user "harry". Alternatively, if you on an on-premise version of Kinetica you, can uncomment the code below to create a new user via SQL.

```sql
-- CREATE USER harry WITH password 'tempPass123!';
```
### Assign a role
Once a user is created we can grant them a role, which would automatically give them all the permissions associated with that role.

```sql
GRANT human_resources TO harry;
```

Follow the same steps as above to create a new user 'bjones' who belongs to engineering.
```sql
-- CREATE USER bjones WITH password 'Engineer123!';
```

```sql
GRANT engineering TO bjones;
```

### 🎯 Task - Login as new users

1. Try logging out and logging back in using the newly created users harry
2. Once you log in you will notice that the schema OurCo or the HR folder that were created the "Create Schema and Directory" sheet are not present for these two users. This is because we haven't given them access yet. We will do so in the next sheet.
3. Repeat 1 & 2 for bjones
4. Log back in as the admin once you have tested the two users to grant permissions in the next sheet.

## Column and Row security
### Grant permissions to a role
A role needs to be [granted permissions](https://docs.kinetica.com/7.1/sql/security/#privilege-management) to tables in an entire schema. We want the human resources team to have full access to the OurCo schema.

```sql
-- Grants full permissions to the OurCo schema and all the tables in it
GRANT ALL ON OurCo TO human_resources;
```
Next let's grant the human_resources role write access to the HR folder so that they can upload csv files for employees and salaries.

```sql
-- Grants write access to the HR folder on KiFS
GRANT WRITE ON HR TO human_resources;
```

### 🎯 Task: Log in as harry and load the csv files into tables in Kinetica
1. Log in as harry who belongs to HR
2. Load the CSV files into HR folder: Now that you the HR role has full access to the HR folder, you can use that to upload the the employees.csv file and the salaries.csv file. Go ahead and do that.
3. Once the files are in the HR folder they can be loaded into a OurCo.Employees and OurCo.Salaries tables that were defined in the first sheet. Use the import wizard to do that.
4. Log back in as admin

### Column security
We want the engineering team to only access the first name, last name, a hash of the cell phone and the last 4 digits of the SSN. We do this with a GRANT statement that picks which columns a role can see. The HASH and MASK functions are a handy way to obfuscate or hide sensitive information.

```sql
GRANT SELECT ON TABLE OurCo.Employees (first_name, last_name, HASH(cell_phone), MASK(ssn, 1, 7, '*')) to engineering;
```

### Row Security
We can also use WHERE clauses to restrict the rows that a user can see. For instance, you can restrict access to salary by setting the user id to who ever is the current user. This would only show the rows where the user id in the salaries table corresponds to the username of the current user.

```sql
GRANT SELECT ON TABLE OurCo.Salaries TO engineering WHERE user_id = CURRENT_USER();
```
We can perform a quick gut check using the SHOW SECURITY statement to make sure the permissions have been assigned correctly.

```sql
SHOW SECURITY FOR harry;
```

```sql
SHOW SECURITY FOR bjones;
```

### 🎯 Task - Log in as bjones to test column and row security
Now, you should be able to see the employees and salaries tables but only the columns you have permissions for and the salary row that corresponds to you.

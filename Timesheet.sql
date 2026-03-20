-- Create the database for the Timesheet system
CREATE DATABASE TimesheetDB;
GO

-- Set the current context to the newly created database
USE TimesheetDB;
GO


-- Create schemas to organize database objects by domain

-- Schema for employee-related data
CREATE SCHEMA hr;
GO

-- Schema for project and timesheet-related data
CREATE SCHEMA project;
GO

-- 1. DEPARTMENTS
-- Stores the list of company departments
-- Used to group employees

CREATE TABLE hr.Departments (
    department_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);
GO

-- 2. EMPLOYEES
-- Stores employee information, ex: personal data, salary, and department assignment
-- details is a JSON column for semi-structured data

CREATE TABLE hr.Employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    hire_date DATE NOT NULL,
    salary DECIMAL(10,2) CHECK (salary > 0),
    department_id INT,
    details NVARCHAR(MAX),

    CONSTRAINT FK_Employees_Department
        FOREIGN KEY (department_id)
        REFERENCES hr.Departments(department_id)
);
GO

-- 3. PROJECTS
-- Stores information about projects including timeline, budget, and status
-- metadata is a JSON column for flexible attributes like client, priority, or technologies

CREATE TABLE project.Projects (
    project_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    budget DECIMAL(12,2) CHECK (budget > 0),
    metadata NVARCHAR(MAX),
    status VARCHAR(20) DEFAULT 'ACTIVE',

    CONSTRAINT CK_Project_Dates CHECK (end_date IS NULL OR end_date >= start_date)
);
GO

-- 4. TASKS
-- Stores tasks associated with projects
-- Each task belongs to a specific project

CREATE TABLE project.Tasks (
    task_id INT PRIMARY KEY,
    project_id INT NOT NULL,
    name VARCHAR(100) NOT NULL,
    estimated_hours INT CHECK (estimated_hours > 0),

    CONSTRAINT FK_Tasks_Project
        FOREIGN KEY (project_id)
        REFERENCES project.Projects(project_id)
);
GO

-- 5. TIMESHEETS
-- Stores timesheet records (one per employee per day)
-- Includes status tracking and creation timestamp
-- Enforces uniqueness so an employee cannot have multiple timesheets for the same day

CREATE TABLE project.Timesheets (
    timesheet_id INT PRIMARY KEY,
    employee_id INT NOT NULL,
    work_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'NEW',
    created_at DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Timesheets_Employee
        FOREIGN KEY (employee_id)
        REFERENCES hr.Employees(employee_id),

    CONSTRAINT UQ_Employee_Date UNIQUE (employee_id, work_date)
);
GO

-- 6. TIMESHEET ENTRIES
-- Stores detailed work entries for each timesheet
-- Each entry links to a project and a task and records worked hours

CREATE TABLE project.TimesheetEntries (
    entry_id INT PRIMARY KEY,
    timesheet_id INT NOT NULL,
    project_id INT NOT NULL,
    task_id INT NOT NULL,
    hours DECIMAL(5,2) CHECK (hours > 0 AND hours <= 24),
    created_at DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_Entries_Timesheet
        FOREIGN KEY (timesheet_id)
        REFERENCES project.Timesheets(timesheet_id),

    CONSTRAINT FK_Entries_Project
        FOREIGN KEY (project_id)
        REFERENCES project.Projects(project_id),

    CONSTRAINT FK_Entries_Task
        FOREIGN KEY (task_id)
        REFERENCES project.Tasks(task_id)
);
GO

-- Insert sample data into all tables

-- DEPARTMENTS
INSERT INTO hr.Departments VALUES
(1, 'IT'),
(2, 'HR'),
(3, 'Finance'),
(4, 'Marketing');


-- EMPLOYEES
INSERT INTO hr.Employees VALUES
(1, 'Ana Popescu', 'ana.popescu@test.com', '2022-01-10', 5000, 1, 
 '{"skills":["SQL","Python"],"level":"mid"}'),

(2, 'Ion Ionescu', 'ion.ionescu@test.com', '2021-03-15', 6000, 1,
 '{"skills":["Java","Spring"],"level":"senior"}'),

(3, 'Maria Georgescu', 'maria.georgescu@test.com', '2023-06-01', 4000, 2,
 '{"skills":["Excel","Recruiting"],"level":"junior"}'),

(4, 'Dan Vasilescu', 'dan.vasilescu@test.com', '2020-09-20', 7000, 3,
 '{"skills":["Accounting"],"level":"senior"}');


-- PROJECTS
INSERT INTO project.Projects VALUES
(1, 'Banking App', '2023-01-01', NULL, 100000,
 '{"client":"ING","priority":"high"}', 'ACTIVE'),

(2, 'HR System', '2023-05-01', NULL, 50000,
 '{"client":"Internal","priority":"medium"}', 'ACTIVE');


-- TASKS
INSERT INTO project.Tasks VALUES
(1, 1, 'Backend Development', 100),
(2, 1, 'Frontend Development', 80),
(3, 2, 'Recruitment Module', 60),
(4, 2, 'Payroll Module', 70);


-- TIMESHEETS
INSERT INTO project.Timesheets (timesheet_id, employee_id, work_date, status)
VALUES
(1, 1, '2024-03-01', 'APPROVED'),
(2, 1, '2024-03-02', 'NEW'),
(3, 2, '2024-03-01', 'APPROVED'),
(4, 3, '2024-03-01', 'SUBMITTED'),
(10, 1, '2024-02-15', 'APPROVED');


-- TIMESHEET ENTRIES
INSERT INTO project.TimesheetEntries (entry_id, timesheet_id, project_id, task_id, hours)
VALUES
(1, 1, 1, 1, 6),
(2, 1, 1, 2, 2),
(3, 2, 1, 1, 8),
(4, 3, 1, 2, 5),
(5, 3, 2, 3, 3),
(6, 4, 2, 3, 7),
(10, 10, 1, 1, 5);

-- Create additional indexes

-- Index on work_date column for faster filtering by date
CREATE NONCLUSTERED INDEX IX_Timesheets_WorkDate
ON project.Timesheets(work_date);
GO

-- Index on status column for faster filtering by status
CREATE NONCLUSTERED INDEX IX_Timesheets_Status
ON project.Timesheets(status);
GO

-- Index on project name for faster searches by project
CREATE NONCLUSTERED INDEX IX_Projects_Name
ON project.Projects(name);
GO

-- Index on employee_id and work_date to optimize filtering by employee and date
CREATE NONCLUSTERED INDEX IX_Timesheets_Employee_Date
ON project.Timesheets(employee_id, work_date);
GO

-- Verify that the indexes were created successfully
SELECT 
    name, 
    object_name(object_id) AS table_name
FROM sys.indexes
WHERE name LIKE 'IX_%';
GO

-- Test query to check index usage (filtering timesheets by status)
SELECT * 
FROM project.Timesheets
WHERE status = 'APPROVED';

-- Shows employee, project, work date and worked hours for each timesheet entry
CREATE OR ALTER VIEW project.View_TimesheetDetails AS
SELECT 
    e.name AS employee_name,
    p.name AS project_name,
    t.work_date,
    te.hours
FROM project.Timesheets t
JOIN hr.Employees e 
    ON t.employee_id = e.employee_id
JOIN project.TimesheetEntries te 
    ON t.timesheet_id = te.timesheet_id
JOIN project.Projects p 
    ON te.project_id = p.project_id;
GO

-- Query the timesheet details view
SELECT * 
FROM project.View_TimesheetDetails;

-- MATERIALIZED VIEW (Indexed View)

-- Creates a view that contains total worked hours per employee per month
CREATE OR ALTER VIEW project.View_TotalHoursPerEmployee_Month
WITH SCHEMABINDING
AS
SELECT 
    e.employee_id,
    e.name,
    YEAR(t.work_date) AS work_year,
    MONTH(t.work_date) AS work_month,
    SUM(ISNULL(te.hours, 0)) AS total_hours,
    COUNT_BIG(*) AS record_count
FROM project.TimesheetEntries te
JOIN project.Timesheets t 
    ON te.timesheet_id = t.timesheet_id
JOIN hr.Employees e 
    ON t.employee_id = e.employee_id
GROUP BY 
    e.employee_id,
    e.name,
    YEAR(t.work_date),
    MONTH(t.work_date);
GO

-- Creates a unique clustered index to materialize the view (store results physically)
CREATE UNIQUE CLUSTERED INDEX IX_View_TotalHours_Month
ON project.View_TotalHoursPerEmployee_Month(employee_id, work_year, work_month);
GO

-- Display the materialized view ordered by employee and month
SELECT * 
FROM project.View_TotalHoursPerEmployee_Month
ORDER BY employee_id, work_year, work_month;

-- This query uses GROUP BY to calculate total worked hours per employee per project per month
SELECT 
    e.name AS employee_name,
    p.name AS project_name,
    YEAR(t.work_date) AS work_year,
    MONTH(t.work_date) AS work_month,
    SUM(te.hours) AS total_hours
FROM project.TimesheetEntries te
JOIN project.Timesheets t 
    ON te.timesheet_id = t.timesheet_id
JOIN hr.Employees e 
    ON t.employee_id = e.employee_id
JOIN project.Projects p 
    ON te.project_id = p.project_id
GROUP BY 
    e.name,
    p.name,
    YEAR(t.work_date),
    MONTH(t.work_date)
ORDER BY 
    e.name,
    work_year,
    work_month;

-- This query uses LEFT JOIN to include all employees, even those without timesheets 
-- and it calculates their total worked hours
SELECT 
    e.name AS employee_name,
    COUNT(t.timesheet_id) AS number_of_timesheets,
    SUM(ISNULL(te.hours, 0)) AS total_hours
FROM hr.Employees e
LEFT JOIN project.Timesheets t 
    ON e.employee_id = t.employee_id
LEFT JOIN project.TimesheetEntries te 
    ON t.timesheet_id = te.timesheet_id
GROUP BY e.name
ORDER BY total_hours DESC;

-- Uses an analytic function (RANK) to rank all employees by total worked hours
-- It includes those with no activity
SELECT 
    e.name AS employee_name,
    SUM(ISNULL(te.hours, 0)) AS total_hours,
    RANK() OVER (ORDER BY SUM(ISNULL(te.hours, 0)) DESC) AS employee_rank
FROM hr.Employees e
LEFT JOIN project.Timesheets t 
    ON e.employee_id = t.employee_id
LEFT JOIN project.TimesheetEntries te 
    ON t.timesheet_id = te.timesheet_id
GROUP BY e.name;

-- Uses AVG() OVER
-- Compares each month's total worked hours with the average monthly hours for the same project
SELECT 
    project_name,
    work_year,
    work_month,
    monthly_hours,
    AVG(monthly_hours) OVER (
        PARTITION BY project_name
    ) AS avg_monthly_hours_per_project
FROM (
    SELECT 
        p.name AS project_name,
        YEAR(t.work_date) AS work_year,
        MONTH(t.work_date) AS work_month,
        SUM(te.hours) AS monthly_hours
    FROM project.TimesheetEntries te
    JOIN project.Timesheets t 
        ON te.timesheet_id = t.timesheet_id
    JOIN project.Projects p 
        ON te.project_id = p.project_id
    GROUP BY 
        p.name,
        YEAR(t.work_date),
        MONTH(t.work_date)
) AS monthly_totals
ORDER BY project_name, work_year, work_month;

-- This trigger ensures that total worked hours per employee per day do not exceed 24
CREATE TRIGGER project.trg_check_daily_hours
ON project.TimesheetEntries
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 
            t.employee_id,
            t.work_date,
            SUM(te.hours) AS total_hours
        FROM project.TimesheetEntries te
        JOIN project.Timesheets t 
            ON te.timesheet_id = t.timesheet_id
        WHERE te.timesheet_id IN (SELECT timesheet_id FROM inserted)
        GROUP BY t.employee_id, t.work_date
        HAVING SUM(te.hours) > 24
    )
    BEGIN
        RAISERROR('Total worked hours per day cannot exceed 24.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- Test insert to verify trigger validation (should raise error)
INSERT INTO project.TimesheetEntries (entry_id, timesheet_id, project_id, task_id, hours)
VALUES (50, 1, 1, 1, 20);

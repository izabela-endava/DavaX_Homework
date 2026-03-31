-- This dimension stores employee information and is populated from the HR system
-- It represents master data and is used to describe who performed the activity
CREATE TABLE Dim_Employee (
    employee_key INT IDENTITY PRIMARY KEY,
    employee_id INT,
    name VARCHAR(100),
    department VARCHAR(100)
);

-- Load employees from the source system
INSERT INTO Dim_Employee (employee_id, name, department)
SELECT 
    e.employee_id,
    e.name,
    d.name
FROM TimesheetDB.hr.Employees e
LEFT JOIN TimesheetDB.hr.Departments d
    ON e.department_id = d.department_id;


-- This dimension represents time and is built by combining all dates from all sources
-- It helps to analyze activities by day, month or year
CREATE TABLE Dim_Date (
    date_key INT IDENTITY PRIMARY KEY,
    full_date DATE,
    day INT,
    month INT,
    year INT,
    weekday_name VARCHAR(20)
);

-- Extract all distinct dates from timesheets, calendar and absence data
-- and transform them into a unified date structure
INSERT INTO Dim_Date (full_date, day, month, year, weekday_name)
SELECT DISTINCT
    d.full_date,
    DAY(d.full_date),
    MONTH(d.full_date),
    YEAR(d.full_date),
    DATENAME(WEEKDAY, d.full_date)
FROM (
    SELECT work_date AS full_date FROM TimesheetDB.project.Timesheets
    UNION
    SELECT CAST(event_start AS DATE) FROM Calendar
    UNION
    SELECT DATEADD(DAY, v.number, a.absence_start)
    FROM Absence_Log a
    CROSS APPLY (
        SELECT number
        FROM master..spt_values
        WHERE type = 'P'
          AND number <= DATEDIFF(DAY, a.absence_start, a.absence_end)
    ) v
) d;


-- This dimension standardizes activity types across all sources
-- It maps different source structures into a common model
CREATE TABLE Dim_ActivityType (
    activity_type_key INT PRIMARY KEY,
    activity_name VARCHAR(50)
);

INSERT INTO Dim_ActivityType VALUES
(1, 'WORK'),
(2, 'MEETING'),
(3, 'ABSENCE');


-- This dimension describes projects to analyze work by project
CREATE TABLE Dim_Project (
    project_key INT IDENTITY PRIMARY KEY,
    project_id INT,
    project_name VARCHAR(100)
);

-- Projects are taken directly from the timesheet system
INSERT INTO Dim_Project (project_id, project_name)
SELECT project_id, name
FROM TimesheetDB.project.Projects;


-- This dimension stores tasks and links them to projects
-- It allows more detailed analysis of what was worked on
CREATE TABLE Dim_Task (
    task_key INT IDENTITY PRIMARY KEY,
    task_id INT,
    task_name VARCHAR(100),
    project_id INT
);

INSERT INTO Dim_Task (task_id, task_name, project_id)
SELECT task_id, name, project_id
FROM TimesheetDB.project.Tasks;


-- This is the central fact table where all activities are integrated
-- Each row represents an activity performed by an employee on a specific day
CREATE TABLE Fact_Activity (
    activity_key INT IDENTITY PRIMARY KEY,
    employee_key INT,
    date_key INT,
    activity_type_key INT,
    project_key INT NULL,
    task_key INT NULL,
    hours DECIMAL(5,2),

    FOREIGN KEY (employee_key) REFERENCES Dim_Employee(employee_key),
    FOREIGN KEY (date_key) REFERENCES Dim_Date(date_key),
    FOREIGN KEY (activity_type_key) REFERENCES Dim_ActivityType(activity_type_key),
    FOREIGN KEY (project_key) REFERENCES Dim_Project(project_key),
    FOREIGN KEY (task_key) REFERENCES Dim_Task(task_key)
);


-- Load work activities from timesheets
-- Save project and task information
INSERT INTO Fact_Activity (
    employee_key,
    date_key,
    activity_type_key,
    project_key,
    task_key,
    hours
)
SELECT 
    de.employee_key,
    dd.date_key,
    1,
    dp.project_key,
    dt.task_key,
    te.hours
FROM TimesheetDB.project.TimesheetEntries te
JOIN TimesheetDB.project.Timesheets t
    ON te.timesheet_id = t.timesheet_id
JOIN Dim_Employee de
    ON t.employee_id = de.employee_id
JOIN Dim_Date dd
    ON t.work_date = dd.full_date
JOIN Dim_Project dp
    ON te.project_id = dp.project_id
JOIN Dim_Task dt
    ON te.task_id = dt.task_id;


-- Load meeting activities from calendar
-- Convert time intervals into hours
INSERT INTO Fact_Activity (
    employee_key,
    date_key,
    activity_type_key,
    hours
)
SELECT 
    de.employee_key,
    dd.date_key,
    2,
    DATEDIFF(MINUTE, c.event_start, c.event_end) / 60.0
FROM Calendar c
JOIN Dim_Employee de
    ON c.employee_id = de.employee_id
JOIN Dim_Date dd
    ON CAST(c.event_start AS DATE) = dd.full_date;


-- Load absence data by splitting intervals into individual days
-- Each day of absence is stored separately with 8 hours
INSERT INTO Fact_Activity (
    employee_key,
    date_key,
    activity_type_key,
    hours
)
SELECT 
    de.employee_key,
    dd.date_key,
    3,
    8
FROM Absence_Log a
JOIN Dim_Employee de
    ON a.employee_id = de.employee_id
CROSS APPLY (
    SELECT DATEADD(DAY, v.number, a.absence_start) AS absence_day
    FROM master..spt_values v
    WHERE v.type = 'P'
      AND v.number <= DATEDIFF(DAY, a.absence_start, a.absence_end)
) d
JOIN Dim_Date dd
    ON d.absence_day = dd.full_date;


-- Final check to see all integrated activities
SELECT * FROM Fact_Activity;
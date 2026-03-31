-- This query shows all activities performed by a specific employee on a given day
-- It combines work, meetings and absences into a single view
SELECT 
    e.name,
    d.full_date,
    at.activity_name,
    p.project_name,
    t.task_name,
    f.hours
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
JOIN Dim_Date d ON f.date_key = d.date_key
JOIN Dim_ActivityType at ON f.activity_type_key = at.activity_type_key
LEFT JOIN Dim_Project p ON f.project_key = p.project_key
LEFT JOIN Dim_Task t ON f.task_key = t.task_key
WHERE e.name = 'Ana Popescu'
  AND d.full_date = '2024-03-01';


-- This query shows all activities by day and by employee
-- It aggregates hours for each activity type per employee and date
SELECT 
    e.name,
    d.full_date,
    at.activity_name,
    SUM(f.hours) AS total_hours
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
JOIN Dim_Date d ON f.date_key = d.date_key
JOIN Dim_ActivityType at ON f.activity_type_key = at.activity_type_key
GROUP BY 
    e.name,
    d.full_date,
    at.activity_name
ORDER BY 
    e.name,
    d.full_date;


-- This query shows how much time each employee spent on each type of activity
-- It helps compare work vs meetings vs absences
SELECT 
    e.name,
    at.activity_name,
    SUM(f.hours) AS total_hours
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
JOIN Dim_ActivityType at ON f.activity_type_key = at.activity_type_key
GROUP BY 
    e.name,
    at.activity_name
ORDER BY 
    e.name;


-- This query focuses on work activities and shows detailed information
-- It analyses what each employee worked on (project and task level)
SELECT 
    e.name,
    d.full_date,
    p.project_name,
    t.task_name,
    SUM(f.hours) AS total_hours
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
JOIN Dim_Date d ON f.date_key = d.date_key
JOIN Dim_Project p ON f.project_key = p.project_key
JOIN Dim_Task t ON f.task_key = t.task_key
WHERE f.activity_type_key = 1
GROUP BY 
    e.name,
    d.full_date,
    p.project_name,
    t.task_name
ORDER BY 
    e.name,
    d.full_date;


-- This query shows how activities are distributed over time
-- It shows how much time is spent daily on each activity type
SELECT 
    d.full_date,
    at.activity_name,
    SUM(f.hours) AS total_hours
FROM Fact_Activity f
JOIN Dim_Date d ON f.date_key = d.date_key
JOIN Dim_ActivityType at ON f.activity_type_key = at.activity_type_key
GROUP BY 
    d.full_date,
    at.activity_name
ORDER BY 
    d.full_date;


-- This query ranks employees based on total worked hours
-- Only work activities are considered for ranking
SELECT 
    e.name,
    SUM(f.hours) AS total_hours,
    RANK() OVER (ORDER BY SUM(f.hours) DESC) AS rank_position
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
WHERE f.activity_type_key = 1
GROUP BY e.name;


-- This query provides a daily summary per employee
-- It separates work, meeting and absence hours into different columns
SELECT 
    e.name,
    d.full_date,
    SUM(CASE WHEN at.activity_name = 'WORK' THEN f.hours ELSE 0 END) AS work_hours,
    SUM(CASE WHEN at.activity_name = 'MEETING' THEN f.hours ELSE 0 END) AS meeting_hours,
    SUM(CASE WHEN at.activity_name = 'ABSENCE' THEN f.hours ELSE 0 END) AS absence_hours
FROM Fact_Activity f
JOIN Dim_Employee e ON f.employee_key = e.employee_key
JOIN Dim_Date d ON f.date_key = d.date_key
JOIN Dim_ActivityType at ON f.activity_type_key = at.activity_type_key
GROUP BY 
    e.name,
    d.full_date
ORDER BY 
    e.name,
    d.full_date;
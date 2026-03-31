-- Create the database
CREATE DATABASE ETL_DB;
GO

-- Create the calendar table where employees have meetings or trainings
CREATE TABLE Calendar (
    event_id INT IDENTITY PRIMARY KEY,
    employee_id INT,
    event_start DATETIME,
    event_end DATETIME,
    event_type VARCHAR(50),
    description VARCHAR(100)
);

-- Insert calendar data 
INSERT INTO Calendar (employee_id, event_start, event_end, event_type, description)
VALUES
(1, '2024-03-01 09:00', '2024-03-01 10:00', 'MEETING', 'Daily Standup'),
(1, '2024-03-02 14:00', '2024-03-02 15:30', 'MEETING', 'Sprint Planning'),
(1, '2024-03-03 09:00', '2024-03-03 09:30', 'MEETING', 'Daily Standup'),
(1, '2024-03-04 11:00', '2024-03-04 12:00', 'MEETING', 'Tech Sync'),
(1, '2024-03-05 15:00', '2024-03-05 16:00', 'MEETING', 'Project Review'),
(2, '2024-03-02 10:00', '2024-03-02 11:00', 'MEETING', 'Daily Standup'),
(2, '2024-03-03 14:00', '2024-03-03 15:00', 'MEETING', 'Client Follow-up'),
(2, '2024-03-01 11:00', '2024-03-01 12:00', 'MEETING', 'Client Call'),
(3, '2024-03-03 10:00', '2024-03-03 11:00', 'TRAINING', 'HR Training'),
(3, '2024-03-02 09:00', '2024-03-02 10:00', 'TRAINING', 'Recruitment Training'),
(3, '2024-03-04 13:00', '2024-03-04 14:00', 'MEETING', 'HR Sync'),
(4, '2024-03-01 10:00', '2024-03-01 11:00', 'MEETING', 'Finance Meeting'),
(4, '2024-03-02 15:00', '2024-03-02 16:00', 'MEETING', 'Budget Review'),
(4, '2024-03-03 09:00', '2024-03-03 10:30', 'TRAINING', 'Finance Training');

-- Create the absence log table
-- The absences are stored as intervals (start and end date)
CREATE TABLE Absence_Log (
    absence_id INT IDENTITY PRIMARY KEY,
    employee_id INT,
    absence_start DATE,
    absence_end DATE,
    absence_type VARCHAR(50),
    reason VARCHAR(100)
);

-- Insert absences data
INSERT INTO Absence_Log (employee_id, absence_start, absence_end, absence_type, reason)
VALUES
(1, '2024-03-06', '2024-03-06', 'ANNUAL_LEAVE', 'Personal leave'),
(2, '2024-03-04', '2024-03-05', 'SICK_LEAVE', 'Flu'),
(3, '2024-03-05', '2024-03-05', 'ANNUAL_LEAVE', 'Vacation'),
(4, '2024-03-03', '2024-03-03', 'SICK_LEAVE', 'Doctor appointment'),
(4, '2024-03-06', '2024-03-07', 'ANNUAL_LEAVE', 'Holiday'),
(2, '2024-03-07', '2024-03-07', 'PERSONAL_LEAVE', 'Personal issue'),
(3, '2024-03-06', '2024-03-06', 'SICK_LEAVE', 'Cold');
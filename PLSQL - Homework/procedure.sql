-- Procedure that updates employee salaries based on commission percentage
CREATE OR REPLACE PROCEDURE ADJUST_SALARIES_BY_COMMISSION IS
BEGIN
  -- Log start of procedure execution
  DEBUG_UTILS.LOG_INFO('adjust_salaries_by_commission', 1, 'Start procedure');

  -- Loop through all employees
  FOR REC IN (
    SELECT employee_id, salary, commission_pct
    FROM employees_copy
  )
  LOOP
    BEGIN
      -- Log current employee being processed
      DEBUG_UTILS.LOG_INFO(
        'adjust_salaries_by_commission',
        10,
        'Processing employee ID: ' || REC.employee_id
      );

      -- Local variable to store new salary
      DECLARE
        V_NEW_SALARY employees_copy.salary%TYPE;
      BEGIN
        -- Apply commission if available
        IF REC.commission_pct IS NOT NULL THEN
          V_NEW_SALARY := REC.salary + REC.salary * REC.commission_pct;

          DEBUG_UTILS.LOG_INFO(
            'adjust_salaries_by_commission',
            20,
            'Commission applied'
          );

          DEBUG_UTILS.LOG_VARIABLE(
            'adjust_salaries_by_commission',
            21,
            'commission_pct',
            REC.commission_pct
          );

        -- Apply default increase if no commission
        ELSE
          V_NEW_SALARY := REC.salary + REC.salary * 0.02;

          DEBUG_UTILS.LOG_WARN(
            'adjust_salaries_by_commission',
            25,
            'No commission -> applied 2%'
          );
        END IF;

        -- Log salary values before and after update
        DEBUG_UTILS.LOG_VARIABLE(
          'adjust_salaries_by_commission',
          30,
          'old_salary',
          REC.salary
        );

        DEBUG_UTILS.LOG_VARIABLE(
          'adjust_salaries_by_commission',
          31,
          'new_salary',
          V_NEW_SALARY
        );

        -- Update employee salary
        UPDATE employees_copy
        SET salary = V_NEW_SALARY
        WHERE employee_id = REC.employee_id;

        DEBUG_UTILS.LOG_INFO(
          'adjust_salaries_by_commission',
          40,
          'Salary updated'
        );

      END;

    -- Handle errors for each employee
    EXCEPTION
      WHEN OTHERS THEN
        DEBUG_UTILS.LOG_ERROR(
          'adjust_salaries_by_commission',
          50,
          SQLERRM
        );
    END;
  END LOOP;

  -- Commit all changes
  COMMIT;

  -- Log end of procedure
  DEBUG_UTILS.LOG_INFO('adjust_salaries_by_commission', 100, 'End procedure');

-- Handle unexpected errors for the whole procedure
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DEBUG_UTILS.LOG_ERROR(
      'adjust_salaries_by_commission',
      999,
      SQLERRM
    );
END;
/
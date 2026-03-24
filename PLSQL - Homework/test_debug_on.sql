-- Test to verify that logs are generated when debug mode is enabled
TRUNCATE TABLE DEBUG_LOG;

BEGIN
  DEBUG_UTILS.ENABLE_DEBUG;
  ADJUST_SALARIES_BY_COMMISSION;
  DEBUG_UTILS.DISABLE_DEBUG;
END;
/

-- Display all generated log entries
SELECT * FROM DEBUG_LOG;
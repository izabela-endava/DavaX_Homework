-- Test to verify that no logs are generated when debug mode is disabled
TRUNCATE TABLE DEBUG_LOG;

BEGIN
  DEBUG_UTILS.DISABLE_DEBUG;
  ADJUST_SALARIES_BY_COMMISSION;
END;
/

-- Check how many log entries were created
SELECT COUNT(*) FROM DEBUG_LOG;
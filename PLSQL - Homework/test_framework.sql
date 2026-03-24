-- Test to verify debugging framework behavior with debug ON and OFF
TRUNCATE TABLE DEBUG_LOG;

-- Debug ON: all logs should be recorded
BEGIN
  DEBUG_UTILS.ENABLE_DEBUG;
  DEBUG_UTILS.LOG_MSG('TEST_MODULE', 10, 'Framework test started');
  DEBUG_UTILS.LOG_VARIABLE('TEST_MODULE', 11, 'test_var', '123');
  DEBUG_UTILS.LOG_ERROR('TEST_MODULE', 12, 'Sample error message');

  -- separator
  DEBUG_UTILS.LOG_MSG('TEST_MODULE', 99, '--------------------');

  DEBUG_UTILS.DISABLE_DEBUG;
END;
/

-- Debug OFF: only error logs should be recorded
BEGIN
  DEBUG_UTILS.DISABLE_DEBUG;
  DEBUG_UTILS.LOG_MSG('TEST_MODULE', 10, 'Framework test started');
  DEBUG_UTILS.LOG_VARIABLE('TEST_MODULE', 11, 'test_var', '123');
  DEBUG_UTILS.LOG_ERROR('TEST_MODULE', 12, 'Sample error message');
END;
/

-- Display all logs
SELECT
  *
FROM
  DEBUG_LOG
ORDER BY
  LOG_ID;
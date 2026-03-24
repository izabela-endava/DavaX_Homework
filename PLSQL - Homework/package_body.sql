-- Package body implementing debugging functionality
CREATE OR REPLACE PACKAGE BODY DEBUG_UTILS AS

  -- Centralized logging procedure used by all logging methods
  PROCEDURE WRITE_LOG(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_MESSAGE VARCHAR2
  ) IS
  BEGIN
    INSERT INTO DEBUG_LOG(MODULE_NAME, LINE_NO, LOG_MESSAGE)
    VALUES (P_MODULE, P_LINE, P_MESSAGE);
  END;

  -- Enable debug mode
  PROCEDURE ENABLE_DEBUG IS
  BEGIN
    G_DEBUG_MODE := TRUE;
  END;

  -- Disable debug mode
  PROCEDURE DISABLE_DEBUG IS
  BEGIN
    G_DEBUG_MODE := FALSE;
  END;

  -- Log a simple message (only when debug is enabled)
  PROCEDURE LOG_MSG(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_MESSAGE VARCHAR2
  ) IS
  BEGIN
    IF G_DEBUG_MODE THEN
      WRITE_LOG(P_MODULE, P_LINE, P_MESSAGE);
    END IF;
  END;

  -- Log variable name and value (only when debug is enabled)
  PROCEDURE LOG_VARIABLE(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_NAME VARCHAR2,
    P_VALUE VARCHAR2
  ) IS
  BEGIN
    IF G_DEBUG_MODE THEN
      WRITE_LOG(P_MODULE, P_LINE, P_NAME || ' = ' || P_VALUE);
    END IF;
  END;

  -- Log error messages (always logged, regardless of debug mode)
  PROCEDURE LOG_ERROR(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_ERROR VARCHAR2
  ) IS
  BEGIN
    WRITE_LOG(P_MODULE, P_LINE, 'ERROR: ' || P_ERROR);
  END;

  -- Log informational messages (only when debug is enabled)
  PROCEDURE LOG_INFO(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_MESSAGE VARCHAR2
  ) IS
  BEGIN
    IF G_DEBUG_MODE THEN
      WRITE_LOG(P_MODULE, P_LINE, 'INFO: ' || P_MESSAGE);
    END IF;
  END;

  -- Log warning messages (only when debug is enabled)
  PROCEDURE LOG_WARN(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_MESSAGE VARCHAR2
  ) IS
  BEGIN
    IF G_DEBUG_MODE THEN
      WRITE_LOG(P_MODULE, P_LINE, 'WARN: ' || P_MESSAGE);
    END IF;
  END;

END DEBUG_UTILS;
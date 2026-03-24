-- Package providing debugging utilities (logging, error handling, debug control)
CREATE OR REPLACE PACKAGE DEBUG_UTILS AS

  -- Global flag used to enable/disable debug logging
  G_DEBUG_MODE BOOLEAN := FALSE;

  -- Enable / disable debug mode
  PROCEDURE ENABLE_DEBUG;
  PROCEDURE DISABLE_DEBUG;

  -- Log a simple message
  PROCEDURE LOG_MSG(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_MESSAGE VARCHAR2
  );

  -- Log variable name and value
  PROCEDURE LOG_VARIABLE(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_NAME VARCHAR2,
    P_VALUE VARCHAR2
  );

  -- Log an error message (always recorded)
  PROCEDURE LOG_ERROR(
    P_MODULE VARCHAR2,
    P_LINE NUMBER,
    P_ERROR VARCHAR2
  );

  -- Log messages with different levels
  PROCEDURE LOG_INFO(P_MODULE VARCHAR2, P_LINE NUMBER, P_MESSAGE VARCHAR2);
  PROCEDURE LOG_WARN(P_MODULE VARCHAR2, P_LINE NUMBER, P_MESSAGE VARCHAR2);

END DEBUG_UTILS;
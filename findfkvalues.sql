/* Formatted by PL/Formatter v3.0.5.0 on 2003/04/29 10:20 */
@SAVE_SQLPLUS_SETTINGS;
SET SERVEROUT ON
ACCEPT V_COLUMN CHAR PROMPT 'Enter column Name: '
ACCEPT V_VALUE  NUMBER PROMPT 'Enter value: '
DECLARE
  CURSOR C_TABS
  IS
    SELECT DISTINCT UTC.TABLE_NAME
    ,UTC.COLUMN_NAME
    ,UTC.DATA_TYPE
    ,UTC.DATA_LENGTH
       FROM USER_TAB_COLUMNS UTC
      WHERE UTC.COLUMN_NAME LIKE UPPER('%&v_column%')
    AND UTC.TABLE_NAME NOT IN
      (
         SELECT VIEW_NAME
           FROM USER_VIEWS
      )
  AND
    (
      UTC.TABLE_NAME IN('OPERATOR_ACCESS_MASTER','OPERATOR_MASTER', 'MAINT_OPERATOR_OPTIONS','OPERATOR_MASTER_HISTORY',
      'OPERATOR_PARENT_COMPANY', 'OPERATOR_ROLES','OPERATOR_ROLES_OVERRIDE','OPERATOR_PROXY')
    OR UTC.TABLE_NAME IN
      (
         SELECT TABLE_NAME
           FROM MAINT_ENTITY_TABLES
          WHERE IN_MOVE = 'Y'
      )
    ) ;
  REC_TABS C_TABS%ROWTYPE;
  V_SQL   VARCHAR2(4000) ;
  V_COUNT NUMBER := 0;
BEGIN
  DBMS_OUTPUT.ENABLE(1000000) ;
  OPEN C_TABS;
  LOOP
    FETCH C_TABS
       INTO REC_TABS;
    EXIT
  WHEN C_TABS%NOTFOUND;
    IF REC_TABS.DATA_TYPE = 'NUMBER' THEN
      V_SQL              := 'SELECT COUNT(ROWID) FROM ' || REC_TABS.TABLE_NAME;
      V_SQL              := V_SQL || ' WHERE ' || REC_TABS.COLUMN_NAME || ' = ' || &V_VALUE;
      EXECUTE IMMEDIATE V_SQL INTO V_COUNT;
      IF V_COUNT > 0 THEN
        DBMS_OUTPUT.PUT_LINE(REC_TABS.TABLE_NAME || '.' || REC_TABS.COLUMN_NAME || ' Count: ' || V_COUNT) ;
        DBMS_OUTPUT.PUT_LINE('SELECT * FROM ' || REC_TABS.TABLE_NAME || ' WHERE ' || REC_TABS.COLUMN_NAME || '=' ||
        &V_VALUE || ';') ;
      ELSE
        NULL;
        DBMS_OUTPUT.put_line('NO RECORDS FOR ' || rec_tabs.table_name || '.' || rec_tabs.column_name) ;
      END IF;
    END IF;
  END LOOP;
  CLOSE C_TABS;
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR( - 20001,SQLERRM) ;
END;
/
@RESTORE_SQLPLUS_SETTINGS;

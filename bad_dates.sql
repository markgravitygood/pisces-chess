-- @C:\Scripts\CR\bad_dates.sql
-- Script to find bad dates across patient data tables
-- DEF: Patient Data Tables: Those tables listed in PAT_MOVE_ENTITY
--
SET TERMOUT ON;
SET FEEDBACK ON;
SET SERVEROUTPUT ON;
SET LINESIZE 10000;
SET VERIFY OFF;
UNDEFINE IN_ENTITY_ID;
UNDEFINE IN_PC_ID;
--
DECLARE
  CURSOR C
  IS
     SELECT U.TABLE_NAME
    ,U.COLUMN_NAME
    ,NVL(E.ENTITY_FIELD,'ENTITY_ID') AS ENTITY_COLUMN_NAME
       FROM MAINT_ENTITY_TABLES E
    INNER JOIN USER_TAB_COLUMNS U
         ON E.TABLE_NAME = U.TABLE_NAME
      WHERE E.IN_MOVE    = 'Y'
    AND U.DATA_TYPE      = 'DATE'
    AND U.COLUMN_NAME   <> 'TIMESTAMP';
  --
  CT_499           NUMBER(10) ;
  CT_CASE          NUMBER(10) ;
  CT_PREF_CASE     NUMBER(10) ;
  CT_PAT_INS_SEQ   NUMBER(10) ;
  OUT_MSG          VARCHAR2(4000) ;
  EXEC_SQL         VARCHAR2(4000) ;
  V_COUNT          NUMBER;
  V_ENTITY_ID      NUMBER;
  V_IN_PC_ID       NUMBER;
  V_PD_PC_ID       NUMBER;
  V_NPP_DT         DATE;
  V_HIE_CONSENT_DT DATE;
  V_PD_PC_NAME MAINT_PARENT_COMPANY.COMPANY_FULLNAME%TYPE;
  V_AN_PC_ID NUMBER;
  V_AN_PC_NAME MAINT_PARENT_COMPANY.COMPANY_FULLNAME%TYPE;
  V_PEM_PC_ID NUMBER;
  V_PEM_PC_NAME MAINT_PARENT_COMPANY.COMPANY_FULLNAME%TYPE;
  V_AN_NAME_ID          NUMBER;
  V_AN_MODIFIED_BY_NAME VARCHAR2(200) ;
  V_AN_TS               VARCHAR2(11) ;
  V_STATUS              VARCHAR2(40) ;
  V_DOB                 DATE;
  V_ENTITY_STATUS_ID PAT_ENTITY_MASTER.ENTITY_STATUS_ID%TYPE;
  V_PD_NOTES PAT_DETAILS.NOTES%TYPE;
  V_PI_ELIG_DATES BOOLEAN := TRUE;
  V_SQL           VARCHAR2(2000) ;
  --
BEGIN
  DBMS_OUTPUT.ENABLE(1000000) ;
  FOR REC IN C
  LOOP
    V_SQL := 'SELECT COUNT(ROWID) FROM ' || REC.TABLE_NAME;
    V_SQL := V_SQL || ' WHERE ' || REC.COLUMN_NAME || ' < TO_DATE(''01-JAN-1900'',''DD-MON-YYYY'')';
    V_SQL := V_SQL || ' AND ' || REC.ENTITY_COLUMN_NAME || ' = ' || &&IN_ENTITY_ID;
    EXECUTE IMMEDIATE V_SQL INTO V_COUNT;
    IF V_COUNT > 0 THEN
      DBMS_OUTPUT.PUT_LINE(REC.TABLE_NAME || '.' || REC.COLUMN_NAME || ' Count: ' || V_COUNT) ;
      V_SQL := 'SELECT ' || REC.COLUMN_NAME || ' FROM ' || REC.TABLE_NAME;
      V_SQL := V_SQL || ' WHERE ' || REC.COLUMN_NAME || ' < TO_DATE(''01-JAN-1900'',''DD-MON-YYYY'')';
      V_SQL := V_SQL || ' AND ' || REC.ENTITY_COLUMN_NAME || ' = ' || &&IN_ENTITY_ID;
      DBMS_OUTPUT.PUT_LINE(V_SQL) ;
    ELSE
      NULL;
      --DBMS_OUTPUT.put_line('NO RECORDS FOR ' || rec.table_name || '.' || rec.column_name) ;
    END IF;
  END LOOP;
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR( - 20001,SQLERRM) ;
END;
/


-- @C:\Scripts\KillMySessions.sql
--ALTER SYSTEM KILL SESSION 'sid,serial#';
COL MYSQL FOR A40;
COL PROGRAM FOR A20;
 SELECT S.SID
,S.SERIAL#
, S.PROGRAM
, 'ALTER SYSTEM KILL SESSION '''
  || S.SID
  || ','
  || S.SERIAL#
  || ''';' AS MYSQL
, S.WAIT_TIME
, S.SECONDS_IN_WAIT
, S.STATUS
, S.OSUSER
   FROM V$SESSION S
  WHERE S.OSUSER in('mark.goodwin', 'mgoodw7','mgoodwin');
  

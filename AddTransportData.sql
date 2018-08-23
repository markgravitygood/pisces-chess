DECLARE 
  -- 
  CURSOR c IS 
    SELECT cts.claim_transaction_summary_id, 
           cts.case_detail_id, B.PAT_PROCEDURE_ID
    FROM   claim_transaction_summary cts 
    INNER JOIN CLAIM_TRANSACTION_DETAIL CTD
    ON CTS.CLAIM_TRANSACTION_SUMMARY_ID = CTD.CLAIM_TRANSACTION_SUMMARY_ID
    INNER JOIN PAT_PROCEDURE_BALANCE B
    ON CTD.PAT_PROCEDURE_BALANCE_ID = B.PAT_PROCEDURE_BALANCE_ID
    WHERE  cts.claim_transaction_summary_id = v_cts_id;

-- 
v_cts_id NUMBER;
V_CASE_DETAIL_ID NUMBER;
V_CASE_ID NUMBER;
V_PT_SEQ NUMBER;
V_PTL_SEQ NUMBER;
V_KFI_SQ NUMBER;
V_CICRC_SEQ NUMBER;
-- 
TYPE t_pt 
IS 
  TABLE OF pat_trip%rowtpye INDEX BY pls_integer; 
  -- 
  a_pt T_PT := T_pt(); 
  -- 
TYPE t_ptl 
IS 
  TABLE OF pat_trip_leg%ROWTYPE INDEX BY PLS_INTEGER; 
  -- 
  a_ptl T_PTL := T_ptl(); 
  -- 
TYPE t_crc 
IS 
  TABLE OF conditions_indicator_crc%ROWTYPE INDEX BY PLS_INTEGER; 
  -- 
  a_crc T_CRC := T_crc(); 
  -- 
TYPE t_k3 
IS 
  TABLE OF k3_file_info%ROWTYPE INDEX BY PLS_INTEGER; 
  -- 
  a_k3 T_K3 := T_k3(); 
  -- 
BEGIN
-- GET THE 
  
EXCEPTION 
WHEN OTHERS THEN 
  raise_application_error(-20001, SQLERRM); 
END;

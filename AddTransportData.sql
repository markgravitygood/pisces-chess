DECLARE 
  -- 
  CURSOR c IS 
    SELECT     cts.claim_transaction_summary_id, 
               cts.case_detail_id, 
               B.pat_procedure_id, 
               P.encounter_id 
    FROM       claim_transaction_summary cts 
    inner join claim_transaction_detail CTD 
    ON         CTS.claim_transaction_summary_id = CTD.claim_transaction_summary_id 
    inner join pat_procedure_balance B 
    ON         CTD.pat_procedure_balance_id = B.pat_procedure_balance_id 
    inner join pat_procedure P 
    ON         B.pat_procedure_id = P.pat_procedure_id 
    WHERE      cts.claim_transaction_summary_id = v_cts_id; 

-- 
v_cts_id         NUMBER := 0; 
v_case_detail_id NUMBER; 
v_case_id        NUMBER; 
v_pt_seq         NUMBER; 
v_ptl_seq        NUMBER; 
v_kfi_sq         NUMBER; 
v_cicrc_seq      NUMBER; 
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
  -- GET THE FOREIGN KEYS NECESSARY 
  SELECT     cts.case_detail_id, 
             B.pat_procedure_id, 
             P.encounter_id 
  INTO       v_case_detail_id, 
             v_pat_procedure_id, 
             v_encounter_id 
  FROM       claim_transaction_summary cts 
  inner join claim_transaction_detail CTD 
  ON         CTS.claim_transaction_summary_id = CTD.claim_transaction_summary_id 
  inner join pat_procedure_balance B 
  ON         CTD.pat_procedure_balance_id = B.pat_procedure_balance_id 
  inner join pat_procedure P 
  ON         B.pat_procedure_id = P.pat_procedure_id 
  WHERE      cts.claim_transaction_summary_id = v_cts_id; 
  
-- CREATE PAT_TRIP DATA -- PAT_TRIP
-- PAT_TRIP RELATES TO THE CASE DETAIL TABLE. BY DEFAULT IT IS ASSOCIATED WUTH THE 2300 LOOP
INSERT INTO PAT_TRIP
(
)
VALUES
(
  )
  ;
  
-- CREATE PAT_TRIP_LEG DATA -- PAT_TRIP
-- PAT_TRIP_LEG RELATES TO THE CASE_DETAIL, PAT_PROCEDURE TABLE. BY DEFAULT IT IS ASSOCIATED WITH THE 2400 LOOP
INSERT INTO PAT_TRIP_LEG
()
VALUES
();
-- CREATE CRC DATA -- CONDITIONS_INDICATOR_CRC
--
INSERT INTO CONDITIONS_INDICATOR_CRC
()
VALUES
();
-- CREATE K3 DATA -- K3_FILE_INFO
INSERT INTO K3_FILE_INFO
()
VALUES
();
EXCEPTION 
WHEN OTHERS THEN 
  Raise_application_error(-20001, SQLERRM); 
END;

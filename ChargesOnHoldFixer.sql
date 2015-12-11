DECLARE
  --
  CURSOR C(IN_HOLD_BATCH_ID NUMBER,IN_PP_ID NUMBER)
  IS
     SELECT PP.GROUP_ID
    ,PP.PAT_PROCEDURE_ID
    ,PP.ENCOUNTER_ID
    , PP.SERVICE_DATE_FROM
    ,PFT.PAT_FINANCIAL_TRANSACTION_ID
    ,B.BATCH_ID
    ,B.BATCH_NAME
    ,B.STATUS
    ,B.ACTIVE
    ,E.HOLD_YN
    ,E.CM_PASSED
    ,PP.UNITS
    ,PFT.PFT_UNITS
    ,PFT.TRANS_DATE
    ,PFT.POSTING_DATE
    ,PP.PP_PARENT_COMPANY_ID
    ,PPB.PAT_PROCEDURE_BALANCE_ID
       FROM PAT_PROCEDURE PP
    ,PAT_PROCEDURE_BALANCE PPB
    ,PAT_FINANCIAL_TRANSACTION PFT
    ,PAT_ENCOUNTER_MASTER E
    ,BATCH_MASTER B
      WHERE PP.PAT_PROCEDURE_ID = PPB.PAT_PROCEDURE_ID
      -- By Pat Procedure Id ("Procedure Line Item Detail"). OPTIONAL
    AND PP.PAT_PROCEDURE_ID IN(178971308, 178971310, 178971314, 178971313, 178971311)
    AND PPB.PAT_PROCEDURE_BALANCE_ID = PFT.PAT_PROCEDURE_BALANCE_ID
    AND PP.ENCOUNTER_ID              = E.ENCOUNTER_ID
      -- By Entity. OPTIONAL
    AND PP.ENTITY_ID IN(24380984)
    AND PFT.BATCH_ID  = B.BATCH_ID
      --AND PFT.POSTING_DATE IS NUL)L
    AND E.HOLD_YN IN('Y','C') 
  --and By Batch Ids
  --AND PFT.BATCH_ID IN (16465527)
  ;
  -- By a specific, support-supplied Hold Batch Id (single). This should be
  -- Commented out if not supplied by Support. OPTIONAL
  --AND PFT.BATCH_ID = IN_HOLD_BATCH_ID;
  --
  --
  --
  -- You would normally change this to the one suplied by Support.
  -- Sometimes they do not supply it. If not, you would modify the
  -- C Cursor above to retrieve the right recordset.
  V_HOLD_BATCH_ID      NUMBER := 16487893; -- Current Hold Batch Id
  V_RFH_BATCH_ID       NUMBER := NULL;     -- Remove From Hold Batch Id
  V_PP_ID              NUMBER := 0;
  V_MODIFIED_BY        NUMBER := 2;
  V_FISCAL_YEAR        NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'YYYY')) ; -- Calendar Year
  V_ACTUAL_FISCAL_YEAR NUMBER;
  V_PERIOD_ID          NUMBER := TO_NUMBER(TO_CHAR(SYSDATE,'MM')) ; -- Calendar Month
  V_FISCAL_PERIOD      NUMBER;
  V_BATCH_NAME BATCH_MASTER.BATCH_NAME%TYPE;
  --
BEGIN
  DBMS_OUTPUT.ENABLE;
  DBMS_OUTPUT.PUT_LINE('PROCESS STARTED.') ;
  -- Construct Batch Name
  V_BATCH_NAME := 'RFH_' || V_HOLD_BATCH_ID ||'_1';
  -- spin Cursor C
  FOR REC IN C(V_HOLD_BATCH_ID,V_PP_ID)
  LOOP
    IF V_RFH_BATCH_ID IS NULL THEN
      -- 1.This creates a "Remove From Hold" batch which is assigned to the
      -- transactions taken off hold. First pass only.
      -- get sequence for Remove From Hold batch
       SELECT SEQ_BATCH_MASTER_ID.NEXTVAL
         INTO V_RFH_BATCH_ID
         FROM DUAL;
      DBMS_OUTPUT.PUT_LINE('V_RFH_BATCH_ID: ' || V_RFH_BATCH_ID) ;
      -- Write Batch Master record
      ADDBATCH_MASTER(V_MODIFIED_BY,V_BATCH_NAME,REC.GROUP_ID,'Y',1,V_PERIOD_ID,V_FISCAL_YEAR,'C',NULL,NULL,
      V_RFH_BATCH_ID,NULL,NULL,NULL,NULL,NULL,NULL) ;
      --
    END IF;
    -- Derive ACTUAL_FISCAL_YEAR and FISCAL_PERIOD
     SELECT FN_CONV_GROUP_FISCALYEAR(V_PERIOD_ID,V_FISCAL_YEAR,REC.PP_PARENT_COMPANY_ID,REC.GROUP_ID)
    ,FN_CONV_GROUP_PERIOD(V_PERIOD_ID,REC.PP_PARENT_COMPANY_ID,REC.GROUP_ID)
       INTO V_ACTUAL_FISCAL_YEAR
    ,V_FISCAL_PERIOD
       FROM DUAL;
    DBMS_OUTPUT.PUT_LINE('V_ACTUAL_FISCAL_YEAR: ' ||V_ACTUAL_FISCAL_YEAR) ;
    DBMS_OUTPUT.PUT_LINE('V_FISCAL_PERIOD: ' ||V_FISCAL_PERIOD) ;
    -- This takes the encounter off "Hold", flagging it as "N", and setting
    -- CM_PASSED to "O" - Override.
    --2. Take the encounters off of hold
     UPDATE PAT_ENCOUNTER_MASTER
    SET HOLD_YN          = 'N'
    ,CM_PASSED           = 'O'
      WHERE ENCOUNTER_ID = REC.ENCOUNTER_ID;
    DBMS_OUTPUT.PUT_LINE('ENCOUNTER UPDATED.') ;
    --3. Move PFT to new batch and flag as posted.
    -- this will asign the pfts the RFH batch ID created above.
     UPDATE PAT_FINANCIAL_TRANSACTION
    SET BATCH_ID                         = V_RFH_BATCH_ID
    ,TIMESTAMP                           = SYSDATE
    ,POSTING_DATE                        = SYSDATE
    ,STATUS                              = 'P'
    ,ACTUAL_FISCAL_YEAR                  = V_ACTUAL_FISCAL_YEAR
    ,FISCAL_YEAR                         = V_FISCAL_YEAR
    ,FISCAL_PERIOD                       = V_FISCAL_PERIOD
    ,PERIOD_ID                           = V_PERIOD_ID
      WHERE PAT_FINANCIAL_TRANSACTION_ID = REC.PAT_FINANCIAL_TRANSACTION_ID;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('PFTs UPDATED.') ;
  -- Run Check Balance Paid Flag procedure to correctly set balance paid flags
  -- Necessary because we moved transactions from one batch to a new batch.
  -- Run on RFH batch only.
  CHECK_BALANCE_PAID_FLAG(V_RFH_BATCH_ID) ;
  DBMS_OUTPUT.PUT_LINE('CHECK_BALANCE_PAID_FLAG EXECUTED.') ;
  -- Close RFH batch.
   UPDATE BATCH_MASTER
  SET ACTIVE       = 'N'
  ,STATUS          = 'C'
    WHERE BATCH_ID = V_RFH_BATCH_ID;
  DBMS_OUTPUT.PUT_LINE('BATCH CLOSED.') ;
  DBMS_OUTPUT.PUT_LINE('PROCESS COMPLETED.') ;
END;
/

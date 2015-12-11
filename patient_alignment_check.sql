SET TERMOUT ON;
SET FEEDBACK ON;
SET SERVEROUTPUT ON;
SET LINESIZE 10000;
SET VERIFY OFF;
UNDEFINE IN_ENTITY_ID;
UNDEFINE IN_PC_ID;
DECLARE
  -- What This Does
  /*
  -- Cursors
  -- ELIGIBILITY DATE Cursor
  -- Get basic demographic info
  -- Check Demo Dates
  -- Checks
  -- check for no private pay insurance
  -- check for active case
  -- check for preferred case
  -- Check for Insurance Sequence 1
  -- Check PC alignment: Pat Details to All Names
  -- Check PC Alignment: Pat Details to Pat Entity Master
  -- Check Primary Referral
  -- Check PC Alignment: Pat Details to Pat Financial Transaction
  -- Check PC Alignment: Pat Details to Pat Procedure Balance
  -- Check PC Alignment: Pat Details to Pat Procedure
  -- Check PC Alignment: Pat Details to Claim Transaction Summary
  -- Check PC Alignment: Pat Details to Pat Appointment
  -- Check PC Alignment: Pat Details to Pat Encounter Master
  -- Check PC Alignment: Pat Details to Pat Insurance
  -- Check Group Alignment by PC on Pat Authorization
  -- Check Eligibility Dates on Pat Insurance records
  */
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
  -- ELIGIBILITY DATE Cursor
  CURSOR C(IN_ENT_ID IN NUMBER)
  IS
     SELECT PI.PAT_INSURANCE_ID
    ,PI.ELIGIBILITY_DATE_FROM
    ,PI.ELIGIBILITY_DATE_TO
       FROM PAT_INSURANCE PI
      WHERE PI.ENTITY_ID = IN_ENT_ID;
BEGIN
  DBMS_OUTPUT.ENABLE(1000000) ;
  OUT_MSG  := '';
  EXEC_SQL := '';
  <<STATUS>>
  BEGIN
    -- Get basic demographic info
     SELECT
      &&IN_PC_ID
       INTO V_IN_PC_ID
       FROM DUAL;
     SELECT D.PARENT_COMPANY_ID
    ,D.DOB
    ,N.NAME_PARENT_COMPANY_ID
    ,D.NPP_DT
    ,D.HIE_CONSENT_DT
       INTO V_PD_PC_ID
    ,V_DOB
    ,V_AN_PC_ID
    ,V_NPP_DT
    ,V_HIE_CONSENT_DT
       FROM PAT_DETAILS D
    INNER JOIN ALL_NAME N
         ON D.NAME_ID   = N.NAME_ID
      WHERE D.ENTITY_ID =
      &&IN_ENTITY_ID;
    DBMS_OUTPUT.PUT_LINE('***************') ;
    DBMS_OUTPUT.PUT_LINE('*** RESULTS ***') ;
    DBMS_OUTPUT.PUT_LINE('***************') ;
    IF V_PD_PC_ID <> V_IN_PC_ID THEN
      DBMS_OUTPUT.PUT_LINE('**** MISALIGNMENT****: PAT DETAILS PC_ID '|| V_PD_PC_ID || ' DOES NOT MATCH GIVEN PCID ' ||
      V_IN_PC_ID) ;
    END IF;
    IF V_AN_PC_ID <> V_IN_PC_ID THEN
      DBMS_OUTPUT.PUT_LINE('**** MISALIGNMENT****: ALL NAME PC_ID '|| V_AN_PC_ID || ' DOES NOT MATCH GIVEN PCID ' ||
      V_IN_PC_ID) ;
    END IF;
    IF TO_CHAR(V_DOB,'YYYY') < 1900 THEN
      DBMS_OUTPUT.PUT_LINE( '**** MISALIGNMENT****: PATIENT APPEARS TO BE BORN PRIOR TO 1900.') ;
    END IF;
    IF V_NPP_DT IS NOT NULL AND TO_CHAR(V_NPP_DT,'YYYY') < 1900 THEN
      DBMS_OUTPUT.PUT_LINE( '**** MISALIGNMENT****: PAT_DETAILS.NPP_DT APPEARS TO BE PRIOR TO 1900.') ;
    END IF;
    IF V_HIE_CONSENT_DT IS NOT NULL AND TO_CHAR(V_HIE_CONSENT_DT,'YYYY') < 1900 THEN
      DBMS_OUTPUT.PUT_LINE( '**** MISALIGNMENT****: PAT_DETAILS.HIE_CONSENT_DT APPEARS TO BE PRIOR TO 1900.') ;
    END IF;
    DBMS_OUTPUT.PUT_LINE('V_PD_PC_ID:'|| V_PD_PC_ID || ';V_AN_PC_ID:' || V_AN_PC_ID) ;
    DBMS_OUTPUT.PUT_LINE('L31') ;
     SELECT STATUS_DESC
      || '('
      || PEM.ENTITY_STATUS_ID
      || ')'
       INTO V_STATUS
       FROM PAT_ENTITY_MASTER PEM
    ,MAINT_ENTITY_STATUS S
      WHERE PEM.ENTITY_STATUS_ID = S.ENTITY_STATUS_ID
    AND PEM.ENTITY_ID            =
      &&IN_ENTITY_ID;
    OUT_MSG := OUT_MSG || ' *** ENTITY STATUS: ' || V_STATUS || ' *** ' || CHR(10) || CHR(13) ;
    -- check for no private pay insurance
    <<PRIVATE_PAY>>
    BEGIN
       SELECT COUNT(0)
         INTO CT_499
         FROM PAT_INSURANCE
        WHERE ENTITY_ID =
        &&IN_ENTITY_ID
      AND INSURANCE_ACTIVE = 'Y'
      AND INSURANCE_ID     = 499;
      IF CT_499           <> 1 THEN
        OUT_MSG           := OUT_MSG ||
        ' *** 72 - Incorrect number of Private Pay Insurance for patient** EXEC COMPACT_PAT_INSURANCE(' ||
        &&IN_ENTITY_ID || ') *** ' || CHR(10) || CHR(13) ;
      END IF;
      -- check for active case
      <<ACTIVE_CASE>>
      BEGIN
         SELECT COUNT(0)
           INTO CT_CASE
           FROM PAT_CASE_MASTER
          WHERE ENTITY_ID =
          &&IN_ENTITY_ID
        AND CASE_ACTIVE = 'Y';
        IF CT_CASE      = 0 THEN
          OUT_MSG      := OUT_MSG || ' *** No ACTIVE case assigned to patient *** ' || CHR(10) || CHR(13) ;
        END IF;
        -- check for preferred case
        <<PREF_CASE>>
        BEGIN
           SELECT COUNT(0)
             INTO CT_PREF_CASE
             FROM PAT_CASE_MASTER
            WHERE ENTITY_ID =
            &&IN_ENTITY_ID
          AND CASE_ACTIVE          = 'Y'
          AND SPECIAL_ATTENTION_YN = 'Y';
          IF CT_PREF_CASE         <> 1 THEN
            OUT_MSG               := OUT_MSG || ' *** Incorrect number of preferred cases assigned to patient *** ' ||
            CHR(10) || CHR(13) ;
          END IF;
          -- Check for Insurance Sequence 1
          <<INS_SEQ_1_COUNT>>
          BEGIN
             SELECT COUNT(0)
               INTO CT_PAT_INS_SEQ
               FROM PAT_INSURANCE
              WHERE INSURANCE_ACTIVE = 'Y'
            AND ENTITY_ID            =
              &&IN_ENTITY_ID
            AND PAT_INSURANCE_SEQ = 1;
            IF CT_PAT_INS_SEQ    <> 1 THEN
              EXEC_SQL           := 'COMPACT_PAT_INSURANCE('|| &&IN_ENTITY_ID || ');' ;
              DBMS_OUTPUT.PUT_LINE('EXEC_SQL: ' || EXEC_SQL) ;
              OUT_MSG := OUT_MSG ||
              ' *** 115 - Incorrect number of insurances set as sequence 1 *** EXEC COMPACT_PAT_INSURANCE(' ||
              &&IN_ENTITY_ID || ') *** ' || CHR(10) || CHR(13) ;
            END IF;
            -- Check PC alignment: Pat Details to All Names
            <<PCID_PD_TO_AN>>
            BEGIN
               SELECT PD.PARENT_COMPANY_ID
              ,PDPC.COMPANY_FULLNAME
              ,AN.NAME_PARENT_COMPANY_ID
              ,ANPC.COMPANY_FULLNAME
              ,AN.NAME_ID
              ,FN_GET_ENTITY_FULLNAME(AN.MODIFIED_BY)
                || '['
                || F_GETOPERATORUSERNAME(GETOPERATORID(PD.ENTITY_ID, PD.PARENT_COMPANY_ID))
                || ']'
              ,TO_CHAR(AN.TIMESTAMP,'DD-MON-YYYY')
              ,PD.NOTES
                 INTO V_PD_PC_ID
              ,V_PD_PC_NAME
              ,V_AN_PC_ID
              ,V_AN_PC_NAME
              ,V_AN_NAME_ID
              ,V_AN_MODIFIED_BY_NAME
              ,V_AN_TS
              ,V_PD_NOTES
                 FROM PAT_DETAILS PD
              ,ALL_NAME AN
              ,MAINT_PARENT_COMPANY PDPC
              ,MAINT_PARENT_COMPANY ANPC
                WHERE PD.NAME_ID            = AN.NAME_ID
              AND PD.PARENT_COMPANY_ID      = PDPC.PARENT_COMPANY_ID
              AND AN.NAME_PARENT_COMPANY_ID = ANPC.PARENT_COMPANY_ID
              AND PD.ENTITY_ID              =
                &&IN_ENTITY_ID
             GROUP BY PD.PARENT_COMPANY_ID
              ,PDPC.COMPANY_FULLNAME
              ,AN.NAME_PARENT_COMPANY_ID
              ,ANPC.COMPANY_FULLNAME
              ,AN.NAME_ID
              ,FN_GET_ENTITY_FULLNAME(AN.MODIFIED_BY)
                || '['
                || F_GETOPERATORUSERNAME(GETOPERATORID(PD.ENTITY_ID, PD.PARENT_COMPANY_ID))
                || ']'
              ,TO_CHAR(AN.TIMESTAMP,'DD-MON-YYYY')
              ,PD.NOTES;
              OUT_MSG := OUT_MSG || ' *** PAT_DETAILS.NOTES: ' || V_PD_NOTES || ' *** ' || CHR(10) || CHR(13) ;
              -- This is a misalignment on the ALL_NAME parent company column.
              IF V_PD_PC_ID <> V_AN_PC_ID THEN
                OUT_MSG     := OUT_MSG || CHR(10) || CHR(13) || ' *** PD.parent_company: ' || V_PD_PC_NAME || '(' ||
                V_PD_PC_ID || ')' || CHR(10) || CHR(13) || ' <> an.name_parent_company: ' || V_AN_PC_NAME || '(' ||
                V_AN_PC_ID || ') alignment issue. ' || CHR(10) || CHR(13) || ' LAST MODIFIED BY NAME(TIMESTAMP): ' ||
                V_AN_MODIFIED_BY_NAME || '(' || V_AN_TS || ') *** ' || CHR(10) || CHR(13) ||
                '; UPDATE ALL_NAME SET NAME_PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE NAME_ID = ' || V_AN_NAME_ID
                || ';';
              END IF;
              -- Check PC Alignment: PAt Details to Pat Entity Master
              <<PCID_PD_TO_PEM>>
              BEGIN
                 SELECT PD.PARENT_COMPANY_ID
                ,PDPC.COMPANY_FULLNAME
                ,PEM.PEM_PARENT_COMPANY_ID
                ,PEMPC.COMPANY_FULLNAME
                ,FN_GET_ENTITY_FULLNAME(PEM.MODIFIED_BY)
                  || '['
                  || F_GETOPERATORUSERNAME(GETOPERATORID(PD.ENTITY_ID, PD.PARENT_COMPANY_ID))
                  || ']'
                ,TO_CHAR(PEM.TIMESTAMP,'DD-MON-YYYY')
                ,PEM.ENTITY_STATUS_ID
                   INTO V_PD_PC_ID
                ,V_PD_PC_NAME
                ,V_PEM_PC_ID
                ,V_PEM_PC_NAME
                ,V_AN_MODIFIED_BY_NAME
                ,V_AN_TS
                ,V_ENTITY_STATUS_ID
                   FROM PAT_DETAILS PD
                ,PAT_ENTITY_MASTER PEM
                ,MAINT_PARENT_COMPANY PDPC
                ,MAINT_PARENT_COMPANY PEMPC
                  WHERE PD.ENTITY_ID          = PEM.ENTITY_ID
                AND PD.PARENT_COMPANY_ID      = PDPC.PARENT_COMPANY_ID
                AND PEM.PEM_PARENT_COMPANY_ID = PEMPC.PARENT_COMPANY_ID
                AND PD.ENTITY_ID              =
                  &&IN_ENTITY_ID
               GROUP BY PD.PARENT_COMPANY_ID
                ,PDPC.COMPANY_FULLNAME
                ,PEM.PEM_PARENT_COMPANY_ID
                ,PEMPC.COMPANY_FULLNAME
                ,FN_GET_ENTITY_FULLNAME(PEM.MODIFIED_BY)
                  || '['
                  || F_GETOPERATORUSERNAME(GETOPERATORID(PD.ENTITY_ID, PD.PARENT_COMPANY_ID))
                  || ']'
                ,TO_CHAR(PEM.TIMESTAMP,'DD-MON-YYYY')
                ,PEM.ENTITY_STATUS_ID;
                -- this is a misalignment on the PAT_ENTITY_MASTER parent company
                -- column.
                IF V_PD_PC_ID <> V_PEM_PC_ID THEN
                  OUT_MSG     := OUT_MSG || CHR(10) || CHR(13) || ' *** PD.PARENT_COMPANY: ' || V_PD_PC_NAME || '(' ||
                  V_PD_PC_ID || ')' || CHR(10) || CHR(13) || ' <> PEM.PEM_PARENT_COMPANY: ' || V_PEM_PC_NAME || '(' ||
                  V_PEM_PC_ID || ') alignment issue. ***;' || CHR(10) || CHR(13) ||
                  ' LAST MODIFIED BY NAME(TIMESTAMP): ' || V_AN_MODIFIED_BY_NAME || '(' || V_AN_TS || ') *** ' || CHR(
                  10) || CHR(13) || ' PATIENT_STATUS:' || V_ENTITY_STATUS_ID || CHR(10) || CHR(13) ||
                  '; UPDATE PAT_ENTITY_MASTER SET PEM_PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' ||
                  &&IN_ENTITY_ID || ';';
                ELSE
                  OUT_MSG := OUT_MSG || ' *** PD.PARENT_COMPANY_ID TO PEM.PEM_PARENT_COMPANY_ID ALIGNMENT CORRECT; ' ||
                  'PATIENT_STATUS:' || V_ENTITY_STATUS_ID;
                END IF;
                -- Check Primary Referral
                <<PD_PRIMARY_REFFERAL>>
                BEGIN
                   SELECT COUNT( *)
                     INTO V_COUNT
                     FROM PAT_DETAILS PD
                    WHERE PRIMARY_REFERRAL_ID   = 0
                  AND PRIMARY_REFERRAL_TYPE_ID <> 0
                  AND PD.ENTITY_ID              =
                    &&IN_ENTITY_ID;
                  IF V_COUNT > 0 THEN
                    OUT_MSG := OUT_MSG ||
                    ' *** Pat Details - Primary Referral Id = 0 for non-zero referral type. Context Issue. *** ' || CHR
                    (10) || CHR(13) ;
                  END IF;
                EXCEPTION
                WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR( - 20001,'PD_PRIMARY_REFFERAL: ' || SQLERRM) ;
                END PD_PRIMARY_REFFERAL;
              EXCEPTION
              WHEN OTHERS THEN
                RAISE_APPLICATION_ERROR( - 20001,'PCID_PD_TO_PEM: ' || SQLERRM) ;
              END PCID_PD_TO_PEM;
            EXCEPTION
            WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR( - 20001,'PCID_PD_TO_AN: ' || SQLERRM) ;
            END PCID_PD_TO_AN;
          EXCEPTION
          WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR( - 20001,'INS_SEQ_1_COUNT: ' || SQLERRM) ;
          END INS_SEQ_1_COUNT;
        EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR( - 20001,'PREF_CASE: ' || SQLERRM) ;
        END PREF_CASE;
      EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR( - 20001,'ACTIVE_CASE: ' || SQLERRM) ;
      END ACTIVE_CASE;
    EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR( - 20001,'PRIVATE_PAY: ' || SQLERRM) ;
    END PRIVATE_PAY;
  EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR( - 20001,'STATUS: ' || SQLERRM) ;
  END STATUS;
  DBMS_OUTPUT.PUT_LINE('RESULTS: ' || OUT_MSG) ;
  DBMS_OUTPUT.PUT_LINE('BASIC DATES/NOTES/NUMBERS CHECK...') ;
  -- Check PC Alignment: Pat Details to Pat Financial Transaction
  V_COUNT := 0;
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_FINANCIAL_TRANSACTION
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT             > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD PFTS BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PFT SET PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' || &&IN_ENTITY_ID
    ) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('PFTS ALIGNED.') ;
  END IF;
  -- Check PC Alignment: Pat Details to Pat Procedure Balance
  V_COUNT := 0;
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_PROCEDURE_BALANCE
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PPB_PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT                 > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD PPBs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PPB SET PPB_PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' ||
    &&IN_ENTITY_ID) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('PPBs ALIGNED.') ;
  END IF;
  -- Check PC Alignment: Pat Details to Pat Procedure
  V_COUNT := 0;
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_PROCEDURE
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PP_PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT                > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD PPs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PAT_PROCEDURE SET PP_PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' ||
    &&IN_ENTITY_ID) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('PPs ALIGNED.') ;
  END IF;
  -- Check PC Alignment: Pat Details to Claim Transaction Summary
  V_COUNT := 0;
   SELECT COUNT( *)
     INTO V_COUNT
     FROM CLAIM_TRANSACTION_SUMMARY
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT             > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD CTSs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE CTS SET PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' || &&IN_ENTITY_ID
    ) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('CTSs ALIGNED.') ;
  END IF;
  V_COUNT := 0;
  -- Check PC Alignment: Pat Details to Pat Appointment
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_APPOINTMENT
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT             > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD APPTs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PAT_APPOINTMENT SET PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' ||
    &&IN_ENTITY_ID) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('APPTs ALIGNED.') ;
  END IF;
  V_COUNT := 0;
  -- Check PC Alignment: Pat Details to Pat Encounter Master
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_ENCOUNTER_MASTER
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT             > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD ENCs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PAT_ENCOUNTER_MASTER SET PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = '
    || &&IN_ENTITY_ID) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('ENCs ALIGNED.') ;
  END IF;
  V_COUNT := 0;
  -- Check PC Alignment: Pat Details to Pat Insurance
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_INSURANCE
    WHERE ENTITY_ID =
    &&IN_ENTITY_ID
  AND PARENT_COMPANY_ID <> V_PD_PC_ID;
  IF V_COUNT             > 0 THEN
    DBMS_OUTPUT.PUT_LINE('BAD PIs BY PC: ' || V_COUNT) ;
    DBMS_OUTPUT.PUT_LINE('UPDATE PAT_INSURANCE SET PARENT_COMPANY_ID = ' || V_PD_PC_ID || ' WHERE ENTITY_ID = ' ||
    &&IN_ENTITY_ID) ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('ENCs ALIGNED.') ;
  END IF;
  V_COUNT := 0;
  -- Check Group Alignment by PC: Pat Details to Pat Authorization
   SELECT COUNT( *)
     INTO V_COUNT
     FROM PAT_AUTHORIZATION
    WHERE
    (
      FROM_DATE    < TO_DATE('01/01/1998','DD/MM/YYYY')
    AND FROM_DATE IS NOT NULL
    OR TO_DATE     < TO_DATE('01/01/1998','DD/MM/YYYY')
    AND TO_DATE   IS NOT NULL
    )
  AND CREATE_GROUP_ID IN
    (
       SELECT GROUP_ID
         FROM MAINT_GROUP
        WHERE PARENT_COMPANY_ID = V_PD_PC_ID
    )
  AND ENTITY_ID =
    &&IN_ENTITY_ID;
  DBMS_OUTPUT.PUT_LINE('BAD Dates on Auths: ' || V_COUNT) ;
  DBMS_OUTPUT.PUT_LINE('Dates on Auths Validated.') ;
  -- Check Eligibility Dates on Pat Insurance records
  FOR REC IN C(&&IN_ENTITY_ID)
  LOOP
    IF REC.ELIGIBILITY_DATE_FROM IS NOT NULL AND REC.ELIGIBILITY_DATE_FROM < TO_DATE( '01-JAN-1900','DD-MON-YYYY') THEN
      DBMS_OUTPUT.PUT_LINE('***ELIGIBILITY_DATE_FROM ERROR***') ;
      DBMS_OUTPUT.PUT_LINE('PAT_INSURANCE_ID = ' || REC.PAT_INSURANCE_ID || ' - PAT_INSURANCE.ELIGIBILITY_DATE_FROM = '
      || TO_CHAR(REC.ELIGIBILITY_DATE_FROM,'DD-MON-YYYY')) ;
      DBMS_OUTPUT.PUT_LINE('#### ASSUMPTION IS IT IS THIS CENTURY - VERIFY!') ;
      DBMS_OUTPUT.PUT_LINE('UPDATE PAT_INSURANCE SET ELIGIBILITY_DATE_FROM = TO_DATE(''' || TO_CHAR(
      REC.ELIGIBILITY_DATE_FROM,'DD-MON') || '-20' || TO_CHAR(REC.ELIGIBILITY_DATE_FROM,'YY') ||
      ''', ''DD-MON-YYYY'')  WHERE PAT_INSURANCE_ID = ' || REC.PAT_INSURANCE_ID || ';') ;
      V_PI_ELIG_DATES := FALSE;
    END IF;
    IF REC.ELIGIBILITY_DATE_TO IS NOT NULL AND REC.ELIGIBILITY_DATE_TO < TO_DATE( '01-JAN-1900','DD-MON-YYYY') THEN
      DBMS_OUTPUT.PUT_LINE('***ELIGIBILITY_DATE_TO ERROR***') ;
      DBMS_OUTPUT.PUT_LINE('PAT_INSURANCE_ID = ' || REC.PAT_INSURANCE_ID || ' - PAT_INSURANCE.ELIGIBILITY_DATE_TO = '
      || TO_CHAR(REC.ELIGIBILITY_DATE_TO, 'DD-MON-YYYY')) ;
      DBMS_OUTPUT.PUT_LINE('#### ASSUMPTION IS IT IS THIS CENTURY - VERIFY!') ;
      DBMS_OUTPUT.PUT_LINE('UPDATE PAT_INSURANCE SET ELIGIBILITY_DATE_TO = TO_DATE(''' || TO_CHAR(
      REC.ELIGIBILITY_DATE_TO,'DD-MON') || '-20' || TO_CHAR(REC.ELIGIBILITY_DATE_TO,'YY') ||
      ''', ''DD-MON-YYYY'')  WHERE PAT_INSURANCE_ID = ' || REC.PAT_INSURANCE_ID || ';') ;
      V_PI_ELIG_DATES := FALSE;
    END IF;
  END LOOP;
  IF V_PI_ELIG_DATES = TRUE THEN
    DBMS_OUTPUT.PUT_LINE( 'PAT INSURANCE ELIGIBILITY DATES FROM/TO ARE ALL VALID OR NULL.') ;
  END IF;
  -- New Section
  -- missing extensions on ATTACHMENT.FILE_NAME cause demographics generic error.
  V_COUNT := 0;
   SELECT COUNT( *)
     INTO V_COUNT
    --   FILE_NAME
    --,SUBSTR(FILE_NAME,LENGTH(FILE_NAME) - 3,4)
    --, original_file_name
     FROM ATTACHMENT
    WHERE INSTR(FILE_NAME,'.') = 0
  AND ENTITY_ID                =
    &&IN_ENTITY_ID;
  IF V_COUNT > 0 THEN
    DBMS_OUTPUT.PUT_LINE('#### ATTACHMENT.FILE_NAME extensions missing!') ;
    DBMS_OUTPUT.PUT_LINE('SELECT FILE_NAME, DISPLAY_NAME, ORIGINAL_FILE_NAME FROM ATTACHMENT WHERE ENTITY_ID = ' ||
    &&IN_ENTITY_ID || ';') ;
  ELSE
    DBMS_OUTPUT.PUT_LINE('#### ATTACHMENT.FILE_NAME extensions OK! ###') ;
  END IF;
  -- New Section
  -- Check for valid VB sensitive Dates in Oracle
  -- Dates prior to 1899
EXCEPTION
WHEN OTHERS THEN
  RAISE_APPLICATION_ERROR( - 20001,'MAIN: ' || SQLERRM) ;
END;
/


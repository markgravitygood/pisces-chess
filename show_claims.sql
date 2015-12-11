/* Formatted by PL/Formatter v3.0.5.0 on 2002/12/26 09:44 */
@SAVE_SQLPLUS_SETTINGS;
COL STATUS_DESC FORMAT A25;
COL FORM_DESC FORMAT A40;
SET PAGESIZE 66;
SET LINESIZE 200;
 SELECT COUNT (*)
, CTS.CLAIM_STATUS_ID
, MCS.DESCRIPTION AS STATUS_DESC
, INSURANCE_FORM_TYPE_ID
, MIFT.DESCRIPTION AS FORM_DESC
   FROM CTS
, MAINT_CLAIM_STATUS MCS
, MIFT
  WHERE GROUP_ID =
  &&GROUP_ID
  AND CTS.CLAIM_STATUS_ID        = MCS.CLAIM_STATUS_ID
  AND CTS.INSURANCE_FORM_TYPE_ID = MIFT.INSURANCE_FORMS_TYPE_ID
  AND CTS.CLAIM_STATUS_ID IN (730,731,732)
GROUP BY CTS.CLAIM_STATUS_ID
, MCS.DESCRIPTION
, INSURANCE_FORM_TYPE_ID
, MIFT.DESCRIPTION
ORDER BY 2;
UNDEFINE GROUP_ID;
@RESTORE_SQLPLUS_SETTINGS;
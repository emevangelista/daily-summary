#!/bin/sh

# Parameters: 
# $1 = SQL_USERNAME  
# $2 = SQL_PASSWORD  
# $3 = START_DATE  
# $4 = END_DATE  
# $5 = PARTITION_MONTH
# $6 = Report Dir  

# Include this
  
# --- Main ---


sqlplus -s $1/$2 << EOF > /dev/null


WHENEVER SQLERROR EXIT FAILURE

SET HEADING ON
SET ECHO OFF
SET HEADERS ON
SET TRIMSPOOL ON
SET NEWPAGE 0
SET SPACE 0
SET LINESIZE 1000
SET PAGESIZE 0
SET FEEDBACK OFF
SET COLSEP ','
SET ARRAYSIZE 5000
SET TERMOUT OFF

SPOOL $6/daily_invc_report_$4.csv



SELECT 'call_inv_dttm', 
'inv_name', 
'rating_grp_name', 
'tier_name', 
'ccy_name',
'chg_type_name',
'ctry_name',
'chg_rate',
'total_ind_cnt',
'total_chg_dur', 
'total_chg_usg',
'total_chg_amt',
'total_tax_amt'
FROM dual;

With BILL_DET as (
SELECT 
TO_CHAR(PC.CALL_DTTM,'YYYY-MM-DD') CALL_DTTM
,PC.INV_NAME            
,PRG.RATING_GRP_NAME     
,TR.TIER_NAME
,CCY.CCY_NAME
,PC.B_NBR_CTRY_NAME 
,PC.CHARGE_TYPE_1 -- PER MINUTE 
,PC.CHARGE_TYPE_2 -- PER CALL/PER HIT
,PC.CHARGE_TYPE_3 -- TRANSIT FEE
,PC.BASE_RATE_1
,PC.BASE_RATE_2
,PC.BASE_RATE_3
,SUM(PC.CHG_DUR2) CHG_DUR          
,DECODE(RPT_TYPE_CODE,5,SUM(PC.CHG_DUR2),SUM((PC.ACTUAL_DUR2) /60)) ACTUAL_DUR
,SUM(PC.BASE_RATE_AMT_1) BASE_RATE_AMT_1    
,SUM(PC.BASE_RATE_AMT_2) BASE_RATE_AMT_2    
,SUM(PC.BASE_RATE_AMT_3) BASE_RATE_AMT_3    
,COUNT(PC.CHARGE_TYPE_1) charge_type_1_cnt
,COUNT(PC.CHARGE_TYPE_2) charge_type_2_cnt
,COUNT(PC.CHARGE_TYPE_3) charge_type_3_cnt
,DECODE(RPT_TYPE_CODE,5,SUM(PC.BASE_RATE_AMT_1 * .12),0) TAX_1  
,DECODE(RPT_TYPE_CODE,5,SUM(PC.BASE_RATE_AMT_2 * .12),0) TAX_2
,DECODE(RPT_TYPE_CODE,5,SUM(PC.BASE_RATE_AMT_3 * .12),0) TAX_3
FROM CRIBS_USER.P_CRIBS_BILL_DET PC  
JOIN CRIBS.PARM_TIER@CRIBSDB_BCV TR ON PC.TIER_CODE = TR.TIER_CODE 
JOIN CRIBS.PARM_CCY@CRIBSDB_BCV  CCY	ON PC.BASE_RATE_CCY_1 = CCY.CCY_ABBR
JOIN CRIBS.PARM_RATING_GRP@CRIBSDB_BCV PRG ON PC.RATING_GRP_CODE = PRG.RATING_GRP_CODE
WHERE   PARTITION_MONTH = '${5}'
AND     CALL_DTTM
BETWEEN to_date('${3}000000', 'yyyymmddhh24miss') 
AND 	to_date('${4}235959', 'yyyymmddhh24miss')
AND 	RPT_TYPE_CODE IN (1,3,5) -- 1 INTL RECEVABLE, 3 INTL TRANSIT, 5 DOM RECEIVABLE	
AND 	rating_hist is NULL
GROUP BY
TO_CHAR(PC.CALL_DTTM,'YYYY-MM-DD') 
,PC.INV_NAME            
,PRG.RATING_GRP_NAME     
,TR.TIER_NAME
,CCY.CCY_NAME
,PC.B_NBR_CTRY_NAME 
,PC.CHARGE_TYPE_1 -- PER MINUTE 
,PC.CHARGE_TYPE_2 -- PER CALL/PER HIT
,PC.CHARGE_TYPE_3 -- TRANSIT FEE
,PC.BASE_RATE_1
,PC.BASE_RATE_2
,PC.BASE_RATE_3
, RPT_TYPE_CODE
)
Select 
CALL_DTTM
|| ',"'  ||INV_NAME            
|| '","' ||RATING_GRP_NAME     
|| '","' ||TIER_NAME
|| '","' ||CCY_NAME
|| '","' ||CHARGE_TYPE_1 
|| '","' ||B_NBR_CTRY_NAME 
|| '","' ||BASE_RATE_1            
|| '","' ||charge_type_1_cnt
|| '","' ||CHG_DUR          
|| '","' ||ACTUAL_DUR
|| '","' ||BASE_RATE_AMT_1    
|| '","' ||TAX_1 || '"'
from BILL_DET 
where charge_type_1 is not null
union all
Select 
CALL_DTTM
|| ',"'  ||INV_NAME            
|| '","' ||RATING_GRP_NAME     
|| '","' ||TIER_NAME
|| '","' ||CCY_NAME
|| '","' ||CHARGE_TYPE_2 
|| '","' ||B_NBR_CTRY_NAME 
|| '","' ||BASE_RATE_2            
|| '","' ||charge_type_2_cnt
|| '","' ||CHG_DUR          
|| '","' ||ACTUAL_DUR
|| '","' ||BASE_RATE_AMT_2    
|| '","' ||TAX_2 || '"'
from BILL_DET 
where charge_type_2 is not null
union all
Select 
CALL_DTTM
|| ',"'  ||INV_NAME            
|| '","' ||RATING_GRP_NAME     
|| '","' ||TIER_NAME
|| '","' ||CCY_NAME
|| '","' ||CHARGE_TYPE_3 
|| '","' ||B_NBR_CTRY_NAME 
|| '","' ||BASE_RATE_3            
|| '","' ||charge_type_3_cnt
|| '","' ||CHG_DUR          
|| '","' ||ACTUAL_DUR
|| '","' ||BASE_RATE_AMT_3    
|| '","' ||TAX_1 || '"'
from BILL_DET 
where charge_type_3 is not null
ORDER BY 1;

SPOOL OFF

EXIT
EOF
# --- End ---
if [ $? -eq 0 ]; then
	exit 0
else
	exit -1
fi



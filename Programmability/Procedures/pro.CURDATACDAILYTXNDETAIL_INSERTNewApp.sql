﻿SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




create PROCEDURE [pro].[CURDATACDAILYTXNDETAIL_INSERTNewApp]
AS
BEGIN
   BEGIN TRY
    
	DECLARE @PROCESSDATE DATE =(SELECT CAST(STARTDATE AS DATE) FROM PRO.EXTDATE_MISDB WHERE FLG='Y')

	DECLARE @TIMEKEY INT=(SELECT TIMEKEY FROM SYSDAYMATRIX WHERE CAST(DATE AS DATE)= @PROCESSDATE)
	
	DELETE FROM TempACDAILYTXNDETAIL --WHERE EXTDATE=@PROCESSDATE
	
	
		UPDATE A SET   COD_TXN_MNEMONIC=B.NEW_TXN_CODE
		FROM  YBL_ACS_MIS.[DBO].ODS_FCR_CH_NOBOOK_CURR A
		INNER JOIN YBL_ACS_MIS.[DBO].ODS_FCR_TRANSACTION_CODE_DECODE B   
		  ON A.COD_TXN_MNEMONIC=B.OLD_TXN_CODE

	
   INSERT INTO  TempACDAILYTXNDETAIL
   (
 CUSTOMERID
,CUSTOMERACID
,TXNDATE
,TXNTYPE
,TXNSUBTYPE
,TXNTIME
,CURRENCYALT_KEY
,CURRENCYCONVRATE
,TXNAMOUNT
,TXNAMOUNTINCURRENCY
,EXTDATE
,TXNREFNO
,TXNVALUEDATE
,MNEMONICCODE
,PARTICULAR
,AUTHORISATIONSTATUS
,CREATEDBY
,DATECREATED
,MODIFIEDBY
,DATEMODIFIED
,APPROVEDBY
,DATEAPPROVED
,REMARK
,TRUECREDIT
,ISPROCESSED
,CTRBATCHNO
,REFSYSTRANO
,UCIF_ID
,REF_CHQ_NO
,TxnValueDate_Source

   )
SELECT
CUSTOMERID='0'
,CUSTOMERACID=COD_ACCT_NO
,TXNDATE=DAT_POST
,TXNTYPE=CASE WHEN COD_DRCR='C' THEN 'CREDIT'  WHEN COD_DRCR='D' THEN 'DEBIT' ELSE NULL END 
,TXNSUBTYPE=CASE WHEN COD_DRCR='C' THEN 'RECOVERY'  WHEN COD_DRCR='D' AND ISNULL(B.ISINTEREST,'N')='I'  THEN 'INTEREST' ELSE 'OTHER INTEREST' END 
,TXNTIME=NULL
,CURRENCYALT_KEY=0
,CURRENCYCONVRATE=rat_conv_TCLCY
,TXNAMOUNT=AMT_TXN
,TXNAMOUNTINCURRENC=amt_txn_tcy
,EXTDATE=@PROCESSDATE
,TXNREFNO=TXN_ID
,TXNVALUEDATE= CASE WHEN COD_TXN_MNEMONIC IN ('6501','9501') THEN  DAT_VALUE ELSE DAT_POST END 
,MNEMONICCODE=COD_TXN_MNEMONIC
,PARTICULAR=TXT_TXN_DESC
,AUTHORISATIONSTATUS=NULL
,CREATEDBY='SSIS'
,DATECREATED=GETDATE()
,MODIFIEDBY=NULL
,DATEMODIFIED=NULL
,APPROVEDBY=NULL
,DATEAPPROVED=NULL
,REMARK=NULL
,CASE WHEN COD_DRCR='C' THEN 'Y' ELSE 'N' END  ---TRUECREDIT='Y'   
,ISPROCESSED='Y'
,CTR_BATCH_NO
,REF_SYS_TR_AUD_NO
,UCIF_ID='0'
,REF_CHQ_NO
,DAT_VALUE
FROM  
YBL_ACS_MIS.DBO.ODS_FCR_CH_NOBOOK_CURR A INNER  JOIN DIMMNEMONICCODE B ON A.COD_TXN_MNEMONIC=B.MNEMONICCODE
 AND B.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND B.EFFECTIVETOTIMEKEY>=@TIMEKEY
WHERE ISNULL(AMT_TXN,0.00)>0

 IF OBJECT_ID('TEMPDB..#TempCustomerUpdate') is not  null 
		   DROP TABLE #TempCustomerUpdate

SELECT Cod_cust CUSTOMERID,Cod_acct_no CUSTOMERACID
INTO #TempCustomerUpdate
 FROM YBL_ACS_MIS..ODS_FCR_CH_ACCT_MAST
 GROUP BY Cod_cust , Cod_acct_no
   
UPDATE A SET A.CUSTOMERID=B.CUSTOMERID
 from  TempACDAILYTXNDETAIL A INNER  JOIN #TempCustomerUpdate B
  ON A.CUSTOMERACID=B.CUSTOMERACID
   WHERE  A.CUSTOMERID='0' AND EXTDATE=@PROCESSDATE


  ----new logic-----
UPDATE A SET  A.UCIF_ID=B.UCIC_ID
from TempACDAILYTXNDETAIL A
	INNER JOIN YBL_ACS_MIS..CustomerData (NOLOCK) B
	ON A.CUSTOMERID=B.FCR_CUSTOMERID
		WHERE (A.UCIF_ID IS NULL OR A.UCIF_ID='0' OR A.UCIF_ID='') 
			and b.UCIc_ID is not null and SourceSystemName='FCR' AND EXTDATE=@PROCESSDATE

------Change done on 12-06-2020 as in some cases UCIF not updated properaly----------

   UPDATE TempACDAILYTXNDETAIL SET UCIF_ID=0 WHERE  UCIF_ID  IS NULL AND  EXTDATE=@PROCESSDATE

UPDATE A SET A.CURRENCYALT_KEY=ISNULL(C.CURRENCYALT_KEY,62) FROM TempACDAILYTXNDETAIL A 
INNER  JOIN YBL_ACS_MIS..ACCOUNTDATA B ON A.CUSTOMERACID=B.ACCOUNTID
INNER JOIN DIMCURRENCY C ON C.CURRENCYCODE=B.CURRENCYCODE
AND (C.EFFECTIVEFROMTIMEKEY<=@TIMEKEY AND C.EFFECTIVETOTIMEKEY>=@TIMEKEY)
WHERE  EXTDATE=@PROCESSDATE AND A.CURRENCYALT_KEY=0

/*---TRUE CREDIT MARKING FOR ACDAILYTXNDETAIL----------------------------*/
/*------INWARDCHEQUE RETURNS(9101)/OUTWARD CHEQUE RETURNS(9501)------------------------------*/

UPDATE A SET A.TRUECREDIT='N' FROM TempACDAILYTXNDETAIL A 
WHERE A.MNEMONICCODE  IN('9101','9501')  AND EXTDATE=@PROCESSDATE 
AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'

/*------------------------DISBURSEMENTS (FCC & FCR)----------------------------------------*/

IF OBJECT_ID('TEMPDB..#COD_TXN_MNEMONIC') IS NOT NULL
   DROP TABLE #COD_TXN_MNEMONIC


SELECT A.COD_TXN_MNEMONIC,TXT_TXN_NARRATIVE, C.COD_ACCT_NO
	INTO #COD_TXN_MNEMONIC
FROM YBL_ACS_MIS.DBO.ODS_FCR_CH_NOBOOK_CURR A 
	 INNER JOIN YBL_ACS_MIS.DBO.ODS_FCR_FFI_STAN_XREF_MMDD C
					ON A.COD_ACCT_NO = C.COD_ACCT_NO
					AND A.CTR_BATCH_NO = C.CTR_BATCH_NO
					AND A.REF_SYS_TR_AUD_NO = C.STAN_NO_FC
					--AND C.TXT_TXN_NARRATIVE  LIKE '%ADJ-ENT%'
					AND A.DAT_VALUE = C.DAT_VALUE       
					AND C.COD_FCC_MODULE = 'CL'
					AND C.COD_TXN_MNEMONIC = '1408'
		WHERE A.COD_TXN_MNEMONIC = '1408'

UPDATE A SET A.TRUECREDIT='N' FROM TempACDAILYTXNDETAIL A 
		INNER JOIN #COD_TXN_MNEMONIC B
			ON A.CustomerAcID=B.COD_ACCT_NO
			AND A.MNEMONICCODE =B.Cod_txn_mnemonic
			AND TXT_TXN_NARRATIVE NOT LIKE '%ADJ-ENT%'
		WHERE  EXTDATE=@PROCESSDATE
			AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'


UPDATE A SET A.TRUECREDIT='N' FROM TempACDAILYTXNDETAIL A 
		INNER JOIN #COD_TXN_MNEMONIC B
			ON A.CustomerAcID=B.COD_ACCT_NO
			AND A.MNEMONICCODE =B.Cod_txn_mnemonic
			AND TXT_TXN_NARRATIVE LIKE '%ADJ-ENT%'
		WHERE  EXTDATE=@PROCESSDATE
			AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'

/*-------------NEFT RETURN(2557)/RTGS RETURN(2555)/RTGS Flex@Corp FUNDS TRANSFER CR(6931)------------------------------*/

UPDATE A SET A.TRUECREDIT='N'  FROM TempACDAILYTXNDETAIL A 
WHERE A.MNEMONICCODE  IN('2557','2555','6909','6931')  AND PARTICULAR LIKE '%RETURN%'
AND A.EXTDATE=@PROCESSDATE AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'

IF OBJECT_ID('TEMPDB..#ACDAILYTXNDETAIL') IS NOT NULL
  DROP TABLE #ACDAILYTXNDETAIL 

SELECT A.CUSTOMERACID,A.TRUECREDIT, PARTICULAR,CAST('' AS VARCHAR(500)) CUSTOMERACID_NEW,CAST('' AS VARCHAR(500)) UCIC_ID_NEW,A.UCIF_ID,Entitykey   INTO #ACDAILYTXNDETAIL
 FROM TempACDAILYTXNDETAIL A
 WHERE EXTDATE=@PROCESSDATE AND A.MNEMONICCODE  IN('1702','1408')
  AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY' 
  
  UPDATE #ACDAILYTXNDETAIL SET  CUSTOMERACID_NEW=RIGHT(PARTICULAR,15)

  UPDATE A SET UCIC_ID_NEW=B.Cod_cust   FROM #ACDAILYTXNDETAIL A
  INNER JOIN YBL_ACS_MIS..ODS_FCR_CH_ACCT_MAST B ON A.CUSTOMERACID_NEW=B.Cod_acct_no


 UPDATE A SET A.TRUECREDIT='N' FROM #ACDAILYTXNDETAIL A
 WHERE UCIC_ID_NEW= UCIF_ID
 AND  UCIF_ID IS NOT NULL 

 
  UPDATE A   SET A.TRUECREDIT=B.TRUECREDIT
 FROM TempACDAILYTXNDETAIL A   INNER JOIN #ACDAILYTXNDETAIL B
   ON A.Entitykey=B.Entitykey
   where A.EXTDATE=@PROCESSDATE  and B.TrueCredit='N'

/*--------------DD LIQUIDATED/CANCELLED-------------------------------------------------------------------------------------*/

UPDATE A SET A.TRUECREDIT='N' FROM TempACDAILYTXNDETAIL A 
WHERE A.MNEMONICCODE  IN('8312','8310','6504','7793','8311') 
AND EXTDATE=@PROCESSDATE AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'


/*----------------SWEEP IN /SWEEP OUT TRANSACTIONS-------------------------------------------------------------------------*/

UPDATE A SET A.TRUECREDIT='N' FROM TempACDAILYTXNDETAIL A 
WHERE A.MNEMONICCODE  IN('1704','1703','1705','1706','1753','1754','9910','9911','1322','9826')
AND EXTDATE=@PROCESSDATE AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'


/*-------------Bulk Combine Corp Cr------------------------------*/

UPDATE A SET A.TRUECREDIT='N'  FROM TempACDAILYTXNDETAIL A 
WHERE A.MNEMONICCODE  IN('6926')  AND PARTICULAR LIKE '%REVERSAL%'
AND A.EXTDATE=@PROCESSDATE AND TXNTYPE='CREDIT'  AND TXNSUBTYPE='RECOVERY'


------------------Add code as per mail from supriya 09-Oct-2020 Audit 1.1.2 not be consider credit from ecbf,eifs and ecfs accounts 15-Dec-2020
Update A set TrueCredit ='N'
from  TempACDAILYTXNDETAIL A (nolock)  inner join ybl_acs_mis.dbo.accountdata (nolock) B on
A.CustomerAcID=b.AccountID
where  EXTDATE= @PROCESSDATE--'2020-10-07'
and TxnType ='CREDIT' and B.ProductCode in ('605','869','891','703','704','705')
-------------------



-------Add code as per mail from  bank not be consider INTEREST from ecbf,eifs and ecfs accounts 12-NOV-2021
Update A set TxnSubType='OTHER INTEREST'
from  TempACDAILYTXNDETAIL A (nolock)  inner join ybl_acs_mis.dbo.accountdata (nolock) B on
A.CustomerAcID=b.AccountID
where  EXTDATE= @PROCESSDATE
and TxnSubType ='INTEREST' and B.ProductCode in ('605','869','891','703','704','705')



INSERT INTO  CURDAT.ACDAILYTXNDETAIL
   (
 CUSTOMERID
,CUSTOMERACID
,TXNDATE
,TXNTYPE
,TXNSUBTYPE
,TXNTIME
,CURRENCYALT_KEY
,CURRENCYCONVRATE
,TXNAMOUNT
,TXNAMOUNTINCURRENCY
,EXTDATE
,TXNREFNO
,TXNVALUEDATE
,MNEMONICCODE
,PARTICULAR
,AUTHORISATIONSTATUS
,CREATEDBY
,DATECREATED
,MODIFIEDBY
,DATEMODIFIED
,APPROVEDBY
,DATEAPPROVED
,REMARK
,TRUECREDIT
,ISPROCESSED
,CTRBATCHNO
,REFSYSTRANO
,UCIF_ID
,REF_CHQ_NO
,TxnValueDate_Source

   )
   select 
   CUSTOMERID
,CUSTOMERACID
,TXNDATE
,TXNTYPE
,TXNSUBTYPE
,TXNTIME
,CURRENCYALT_KEY
,CURRENCYCONVRATE
,TXNAMOUNT
,TXNAMOUNTINCURRENCY
,EXTDATE
,TXNREFNO
,TXNVALUEDATE
,MNEMONICCODE
,PARTICULAR
,AUTHORISATIONSTATUS
,CREATEDBY
,DATECREATED
,MODIFIEDBY
,DATEMODIFIED
,APPROVEDBY
,DATEAPPROVED
,REMARK
,TRUECREDIT
,ISPROCESSED
,CTRBATCHNO
,REFSYSTRANO
,UCIF_ID
,REF_CHQ_NO
,TxnValueDate_Source
from  TempACDAILYTXNDETAIL


-------------------

    --DROP TABLE #TempTableCod_txn_mnemonic
	DROP TABLE #COD_TXN_MNEMONIC
	DROP TABLE #TempCustomerUpdate
	DROP TABLE #ACDAILYTXNDETAIL

END TRY
BEGIN CATCH
      SELECT 'ERROR MESSAGE :'+ERROR_MESSAGE()+'ERROR PROCEDURE :'+ERROR_PROCEDURE();
END  CATCH
END 








GO
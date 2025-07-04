﻿SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROC [pro].[CoBorrowerDetails_Insertfinalbackup] 
AS


 DECLARE @TIMEKEY INT = (SELECT TimeKey FROM PRO.EXTDATE_MISDB WHERE Flg='Y')   
 DECLARE @PROCESSDATE DATE= (SELECT DATE FROM SYSDAYMATRIX WHERE TIMEKEY=@TIMEKEY)     
 Declare @vEffectiveto INT Set @vEffectiveto=(select Timekey-1 from PRO.EXTDATE_MISDB where Flg='Y')
     
--select 	 @TIMEKEY  ,@PROCESSDATE ,@vEffectiveto
/********@vEffectiveto*delete duplicate data from COBORROWER_DATA table***************************/
IF OBJECT_ID('TEMPDB..#COBORROWER_DATA') IS NOT NULL
      DROP TABLE #COBORROWER_DATA

SELECT A.*, 'C' AS StatusFlag,CAST(NULL AS VARCHAR(50)) AS SourceSystemCustomerID ,CAST(NULL AS VARCHAR(50)) AS UCIF_ID,CAST(NULL AS VARCHAR(50)) AS PANNO 
INTO #COBORROWER_DATA FROM YBL_ACS_MIS.dbo.COBORROWER_DATA A



UPDATE A SET StatusFlag='A'
FROM #COBORROWER_DATA A
INNER JOIN YBL_ACS_MIS.dbo.AccountData B
ON A.AGREEMENTNO=B.AccountID


UPDATE A
		SET A.SourceSystemCustomerID=B.SourceSystemCustomerID,A.UCIF_ID=B.UCIF_ID
	FROM #COBORROWER_DATA A
		INNER JOIN Pro.accountcal B
			ON A.[AGREEMENTNO]=B.CustomerAcID

UPDATE A
		SET A.PANNO=B.PANNO
	FROM #COBORROWER_DATA A
		INNER JOIN Pro.CustomerCal  B
			ON A.SourceSystemCustomerID=B.SourceSystemCustomerID
WHERE B.PANNO IS NOT NULL



;WITH _CTE_COBORROWER_DATA
	AS
		(
			SELECT ROW_NUMBER() OVER ( PARTITION BY APPLID,AGREEMENTNO,FLAG,CO_APPLICANT_FIN_CUST_ID,CO_APPLICANT_FCR_CUST_ID,CO_APPLICANT_UCIC
,CO_APPLICANT_NAME,APPLICANT_FIN_CUST_ID,APPLICANT_FCR_CUST_ID,APPLICANT_UCIC,APPLICANT_NAME,ETL_DATE,StatusFlag ORDER BY APPLID) RN,*
FROM #COBORROWER_DATA where StatusFlag='A'
		) 
	DELETE  FROM _CTE_COBORROWER_DATA WHERE RN>1

	

TRUNCATE TABLE PRO.TempCoBorrowerDetails 
 
INSERT INTO PRO.TempCoBorrowerDetails 
		   (
		    [CoBorrowerID]
		   ,RefCustomerID
		   ,[APPLID]
		   ,[AGREEMENTNO]
		   ,[FLAG]
		   ,[CO_APPLICANT_FIN_CUST_ID]
		   ,[CO_APPLICANT_FCR_CUST_ID]
		   ,[CO_APPLICANT_UCIC]
		   ,[CO_APPLICANT_NAME]
		   ,[APPLICANT_FIN_CUST_ID]
		   ,[APPLICANT_FCR_CUST_ID]
		   ,[APPLICANT_UCIC]
		   ,[APPLICANT_NAME]
		   ,[AuthorisationStatus]
		   ,[EffectiveFromTimeKey]
		   ,[EffectiveToTimeKey]
		   ,[CreatedBy]
		   ,[DateCreated]
		   ,[ModifiedBy]
		   ,[DateModified]
		   ,[ApprovedBy]
		   ,[DateApproved]
		   ,[SourceSystemCustomerID]
	           ,[UCIF_ID] 
	           ,[PANNO]
		   )
 select  
			 [CO_APPLICANT_FCR_CUST_ID] as CoBorrowerID
			,[APPLICANT_FCR_CUST_ID] as RefCustomerID
			,[APPLID]
			,[AGREEMENTNO]
			,[FLAG]
			,[CO_APPLICANT_FIN_CUST_ID]
			,[CO_APPLICANT_FCR_CUST_ID]
			,[CO_APPLICANT_UCIC]
			,[CO_APPLICANT_NAME]
			,[APPLICANT_FIN_CUST_ID]
			,[APPLICANT_FCR_CUST_ID]
			,[APPLICANT_UCIC]
			,[APPLICANT_NAME]
			,'A'
			,@TIMEKEY
			,49999
			,'D2K'
			,GETDATE()
			,NULL
			,NULL
			,NULL
			,NULL
			,[SourceSystemCustomerID]
	           	,[UCIF_ID] 
	               ,[PANNO]
			FROM #COBORROWER_DATA where StatusFlag='A'


/*amar - 27122023 --insert ACCOUNT data missing in co-borrower data to maintain flags and use   */
insert into PRO.TempCoBorrowerDetails
		   (
		    [CoBorrowerID]
		   ,RefCustomerID
		   ,[APPLID]
		   ,[AGREEMENTNO]
		   ,[FLAG]
		   ,[CO_APPLICANT_FIN_CUST_ID]
		   ,[CO_APPLICANT_FCR_CUST_ID]
		   ,[CO_APPLICANT_UCIC]
		   ,[CO_APPLICANT_NAME]
		   ,[APPLICANT_FIN_CUST_ID]
		   ,[APPLICANT_FCR_CUST_ID]
		   ,[APPLICANT_UCIC]
		   ,[APPLICANT_NAME]
		   ,[AuthorisationStatus]
		   ,[EffectiveFromTimeKey]
		   ,[EffectiveToTimeKey]
		   ,[CreatedBy]
		   ,[DateCreated]
		   ,[ModifiedBy]
		   ,[DateModified]
		   ,[ApprovedBy]
		   ,[DateApproved]
		   ,[SourceSystemCustomerID]
	           ,[UCIF_ID] 
	           ,[PANNO]
		   )
select null CoBorrowerID, A.RefCustomerID, NULL APPLID, CustomerAcID AGREEMENTNO,
'D' FLAG,NULL CO_APPLICANT_FIN_CUST_ID, NULL CO_APPLICANT_FCR_CUST_ID, NULL CO_APPLICANT_UCIC, NULL CO_APPLICANT_NAME
,A.RefCustomerID APPLICANT_FIN_CUST_ID, A.RefCustomerID APPLICANT_FCR_CUST_ID, A.UCIF_ID APPLICANT_UCIC,
B.CustomerName APPLICANT_NAME, NULL AuthorisationStatus, a.EffectiveFromTimeKey,49999 EffectiveToTimeKey, 'D2K'CreatedBy
, GETDate() DateCreated, null ModifiedBy,null  DateModified,null  ApprovedBy, null DateApproved,
 a.SourceSystemCustomerID, a.UCIF_ID, b.PANNO
 FROM pro.AccountCal A
	INNER JOIN PRO.CustomerCal B
		ON A.CUSTOMERENTITYID=B.CUSTOMERENTITYID
	left join PRO.TempCoBorrowerDetails c
		ON C.AGREEMENTNO=a.CustomerAcID
where c.AGREEMENTNO is null
	and a.RefCustomerID in(select CoBorrowerID from PRO.TempCoBorrowerDetails
			union select RefCustomerID from PRO.TempCoBorrowerDetails
						 )


insert into PRO.TempCoBorrowerDetails
		   (
		    [CoBorrowerID]
		   ,RefCustomerID
		   ,[APPLID]
		   ,[AGREEMENTNO]
		   ,[FLAG]
		   ,[CO_APPLICANT_FIN_CUST_ID]
		   ,[CO_APPLICANT_FCR_CUST_ID]
		   ,[CO_APPLICANT_UCIC]
		   ,[CO_APPLICANT_NAME]
		   ,[APPLICANT_FIN_CUST_ID]
		   ,[APPLICANT_FCR_CUST_ID]
		   ,[APPLICANT_UCIC]
		   ,[APPLICANT_NAME]
		   ,[AuthorisationStatus]
		   ,[EffectiveFromTimeKey]
		   ,[EffectiveToTimeKey]
		   ,[CreatedBy]
		   ,[DateCreated]
		   ,[ModifiedBy]
		   ,[DateModified]
		   ,[ApprovedBy]
		   ,[DateApproved]
		   ,[SourceSystemCustomerID]
	           ,[UCIF_ID] 
	          ,[PANNO]
		   )
select null CoBorrowerID, A.RefCustomerID, NULL APPLID, CustomerAcID AGREEMENTNO,
'D' FLAG,NULL CO_APPLICANT_FIN_CUST_ID, NULL CO_APPLICANT_FCR_CUST_ID, NULL CO_APPLICANT_UCIC, NULL CO_APPLICANT_NAME
,A.RefCustomerID APPLICANT_FIN_CUST_ID, A.RefCustomerID APPLICANT_FCR_CUST_ID, A.UCIF_ID APPLICANT_UCIC,
B.CustomerName APPLICANT_NAME, NULL AuthorisationStatus, a.EffectiveFromTimeKey,49999 EffectiveToTimeKey, 'D2K'CreatedBy
, GETDate() DateCreated, null ModifiedBy,null  DateModified,null  ApprovedBy, null DateApproved,
 a.SourceSystemCustomerID, a.UCIF_ID, b.PANNO
 FROM pro.AccountCal A
	INNER JOIN PRO.CustomerCal B
		ON A.UcifEntityID=B.UcifEntityID
	left join PRO.TempCoBorrowerDetails c
		ON C.AGREEMENTNO=a.CustomerAcID
where c.AGREEMENTNO is null
	and a.UCIF_ID in(select CO_APPLICANT_UCIC from PRO.TempCoBorrowerDetails
		union   select APPLICANT_UCIC from PRO.TempCoBorrowerDetails
						 )
 


UPDATE A SET 
 A.FlgDeg =B.FlgDeg 
,A.DegDate=B.DegDate
,A.FlgUpg =B.FlgUpg 
,A.UpgDate=B.UpgDate
,A.Pri_Assetclassalt_key = B.Pri_Assetclassalt_key
,A.Pri_NPADate			 = B.Pri_NPADate
,A.Co_Assetclassalt_key	 = B.Co_Assetclassalt_key
,A.Co_NPADate			 = B.Co_NPADate

--SELECT COUNT(1)
FROM PRO.TempCoBorrowerDetails  a
INNER JOIN PRO.CoBorrowerDetails  b 
ON b.EffectiveFromTimeKey<= @TimeKey AND b.EffectiveToTimeKey>=@TimeKey
AND a.RefCustomerID=b.RefCustomerID
AND Isnull(A.CoBorrowerID,a.CO_APPLICANT_FIN_CUST_ID)=Isnull(B.CoBorrowerID,B.CO_APPLICANT_FIN_CUST_ID)

UPDATE A SET 
 A.FlgDeg =B.FlgDeg 
,A.DegDate=B.DegDate
,A.FlgUpg =B.FlgUpg 
,A.UpgDate=B.UpgDate
,A.Pri_Assetclassalt_key = B.Pri_Assetclassalt_key
,A.Pri_NPADate			 = B.Pri_NPADate
,A.Co_Assetclassalt_key	 = B.Co_Assetclassalt_key
,A.Co_NPADate			 = B.Co_NPADate

--SELECT COUNT(1)
FROM PRO.TempCoBorrowerDetails  a
INNER JOIN PRO.CoBorrowerDetails  b 
ON b.EffectiveFromTimeKey<= @TimeKey AND b.EffectiveToTimeKey>=@TimeKey
AND a.RefCustomerID=b.RefCustomerID
AND B.FLAG='D' AND A.AGREEMENTNO=B.AGREEMENTNO

MERGE PRO.CoBorrowerDetails   O
USING PRO.TempCoBorrowerDetails  T
ON 
	O.[APPLID]						=	T.[APPLID]
AND O.[AGREEMENTNO]					=	T.[AGREEMENTNO]
AND O.[CO_APPLICANT_FIN_CUST_ID]	=	T.[CO_APPLICANT_FIN_CUST_ID]
AND O.[CO_APPLICANT_FCR_CUST_ID]	=	T.[CO_APPLICANT_FCR_CUST_ID]
AND o.RefCustomerID					=	t.RefCustomerID
AND O.[CO_APPLICANT_UCIC]			=	T.[CO_APPLICANT_UCIC]
AND O.[APPLICANT_FIN_CUST_ID]		=	T.[APPLICANT_FIN_CUST_ID]
AND O.[APPLICANT_FCR_CUST_ID]		=	T.[APPLICANT_FCR_CUST_ID]
AND O.[APPLICANT_UCIC]				=	T.[APPLICANT_UCIC]
AND O.SourceSystemCustomerID		=	T.SourceSystemCustomerID
and ISNULL(O.UCIF_ID,'')			= ISNULL(T.UCIF_ID,'')
and ISNULL(O.PANNO,'')				= ISNULL(T.PANNO,'')
AND O.EffectiveToTimeKey=49999
WHEN MATCHED 
AND 
(

	   ISNULL(O.[CoBorrowerID],'')		<> ISNULL(T.[CoBorrowerID],'')				
	OR ISNULL(O.[FLAG],'')				<> ISNULL(T.[FLAG],'')
	OR ISNULL(O.[CO_APPLICANT_NAME],'')	<> ISNULL(T.[CO_APPLICANT_NAME],'')
	OR ISNULL(O.[APPLICANT_NAME],'')	<> ISNULL(T.[APPLICANT_NAME],'')
	OR ISNULL(O.FlgDeg,'')				<> ISNULL(T.FlgDeg,'')
	OR ISNULL(O.DegDate,'1900-01-01')	<> ISNULL(T.DegDate,'1900-01-01')
	OR ISNULL(O.FlgUpg,'')				<> ISNULL(T.FlgUpg,'')
	OR ISNULL(O.UpgDate,'1900-01-01')	<> ISNULL(T.UpgDate,'1900-01-01')
	----OR ISNULL(O.SourceSystemCustomerID,'')<> ISNULL(T.SourceSystemCustomerID,'')
	----OR ISNULL(O.UCIF_ID,'')				<> ISNULL(T.UCIF_ID,'')
	----OR ISNULL(O.PANNO,'')				<> ISNULL(T.PANNO,'')

)
Then
UPDATE SET 
O.EffectiveToTimeKey=@vEffectiveto;


MERGE PRO.CoBorrowerDetails   O
USING PRO.TempCoBorrowerDetails  T
ON 
	ISNULL(O.[APPLID],'')						=	ISNULL(T.[APPLID],'')
AND ISNULL(O.[AGREEMENTNO],'')					=	ISNULL(T.[AGREEMENTNO],'')
AND ISNULL(O.[CO_APPLICANT_FIN_CUST_ID],'')	=	ISNULL(T.[CO_APPLICANT_FIN_CUST_ID],'')
AND ISNULL(O.[CO_APPLICANT_FCR_CUST_ID],'')	=	ISNULL(T.[CO_APPLICANT_FCR_CUST_ID],'')
AND ISNULL(O.[CO_APPLICANT_UCIC],'')			=	ISNULL(T.[CO_APPLICANT_UCIC],'')
AND ISNULL(O.[APPLICANT_FIN_CUST_ID],'')		=	ISNULL(T.[APPLICANT_FIN_CUST_ID],'')
AND ISNULL(O.[APPLICANT_FCR_CUST_ID],'')		=	ISNULL(T.[APPLICANT_FCR_CUST_ID],'')
AND ISNULL(O.[APPLICANT_UCIC],'')				=	ISNULL(T.[APPLICANT_UCIC],'')
AND ISNULL(o.RefCustomerID,'')					=	ISNULL(t.RefCustomerID,'')
AND ISNULL(O.SourceSystemCustomerID,'')		=	ISNULL(T.SourceSystemCustomerID,'')
and ISNULL(O.UCIF_ID,'')			= ISNULL(T.UCIF_ID,'')
and ISNULL(O.PANNO,'')				= ISNULL(T.PANNO,'')
AND O.EffectiveToTimeKey=49999
WHEN NOT MATCHED 
THEN
INSERT 
		   (
				 [CoBorrowerID]
				,[RefCustomerID]
				,[APPLID]
				,[AGREEMENTNO]
				,[FLAG]
				,[CO_APPLICANT_FIN_CUST_ID]
				,[CO_APPLICANT_FCR_CUST_ID]
				,[CO_APPLICANT_UCIC]
				,[CO_APPLICANT_NAME]
				,[APPLICANT_FIN_CUST_ID]
				,[APPLICANT_FCR_CUST_ID]
				,[APPLICANT_UCIC]
				,[APPLICANT_NAME]
				,[EffectiveFromTimeKey]
				,[EffectiveToTimeKey]
				,[CreatedBy]
				,[DateCreated]
				,[FlgDeg]
				,[DegDate]
				,[FlgUpg]
				,[UpgDate]
				,[SourceSystemCustomerID]
				,[UCIF_ID]
				,[PANNO]
				,Pri_Assetclassalt_key 
		   		 ,Pri_NPADate			 
		   		 ,Co_Assetclassalt_key	 
		   		,Co_NPADate			 
		   
		   
		   )

VALUES 
			(
				 T.[CoBorrowerID]
				,T.RefCustomerID
				,T.[APPLID]
				,T.[AGREEMENTNO]
				,T.[FLAG]
				,T.[CO_APPLICANT_FIN_CUST_ID]
				,T.[CO_APPLICANT_FCR_CUST_ID]
				,T.[CO_APPLICANT_UCIC]
				,T.[CO_APPLICANT_NAME]
				,T.[APPLICANT_FIN_CUST_ID]
				,T.[APPLICANT_FCR_CUST_ID]
				,T.[APPLICANT_UCIC]
				,T.[APPLICANT_NAME]
				,T.[EffectiveFromTimeKey]
				,T.[EffectiveToTimeKey]
				,T.[CreatedBy]
				,T.[DateCreated]
				,T.[FlgDeg]
				,T.[DegDate]
				,T.[FlgUpg]
				,T.[UpgDate]
   				,T.[SourceSystemCustomerID]
				,T.[UCIF_ID]
				,T.[PANNO]
				,T.Pri_Assetclassalt_key 
		   		,T.Pri_NPADate			 
		   		,T.Co_Assetclassalt_key	 
		   		,T.Co_NPADate
		);


	IF @TIMEKEY =26851--26886 /* update FlgDeg ='Y' NAD deGdaTE AS fINALnPADATE FOR THE NPA ACCOUNT WHEN CO-BORROWER IMPLEMENTATION - TO BE EXECUTE ONLY ONCE */
		BEGIN
			
			UPDATE A
				SET 
				FlgDeg='Y',
				DegDate=FinalNpaDt,
				A.Pri_Assetclassalt_key= b.FinalAssetClassAlt_Key,
				A.Pri_NPADate=b.FinalNpaDt
		 	FROM Pro.CoBorrowerDetails  A
				INNER JOIN Pro.accountcal B
					ON A.[AGREEMENTNO]=B.CustomerAcID
			WHERE B.FinalAssetClassAlt_Key>1


			IF OBJECT_ID('TEMPDB..#CUST_SELF_NPA') IS NOT NULL
			DROP TABLE #CUST_SELF_NPA

			SELECT B.RefCustomerID,a.SourceSystemCustomerID, a.UCIF_ID,PANNO
				INTO #CUST_SELF_NPA
			FROM Pro.CoBorrowerDetails  A   
				INNER JOIN Pro.accountcal B 
				ON A.CoBorrowerID =B.RefCustomerID
				WHERE A.FlgDeg='Y'
				and B.FinalAssetClassAlt_Key>1
				GROUP BY B.RefCustomerID,a.SourceSystemCustomerID, a.UCIF_ID,PANNO

				UPDATE A
					 SET A.DegDate=SysNPA_Dt
						,A.FlgDeg='Y'
						,A.Co_Assetclassalt_key=SysAssetClassAlt_Key
		FROM Pro.CoBorrowerDetails A 
					INNER JOIN #CUST_SELF_NPA B
						ON A.RefCustomerID=B.RefCustomerID
						--AND (A.EffectiveFromTimeKey<=@TIMEKEY and a.EffectiveToTimeKey>=@TIMEKEY)
					INNER JOIN Pro.CustomerCal c
						on a.RefCustomerID=c.RefCustomerID
						--and isnull(c.TotOsCust,0)>0
					WHERE isnull(A.FlgDeg,'N')='N'

				

				/*UPDATE DEG DATE AND FLAG FOR THE SOURCESYSTEMCUSTOMERID UNDER NPA CRITERIA*/
				UPDATE A
					 SET A.DegDate=SysNPA_Dt
						,A.FlgDeg='Y'
						,A.Co_Assetclassalt_key=SysAssetClassAlt_Key
						,A.Co_NPADate=SysNPA_Dt
				FROM Pro.CoBorrowerDetails A 
					INNER JOIN #CUST_SELF_NPA B
						ON A.RefCustomerID=B.RefCustomerID
						--AND (A.EffectiveFromTimeKey<=@TIMEKEY and a.EffectiveToTimeKey>=@TIMEKEY)
					INNER JOIN Pro.CustomerCal c
						on A.SourceSystemCustomerID=C.SourceSystemCustomerID
						and isnull(c.TotOsCust,0)>0
					WHERE isnull(A.FlgDeg,'N')='N' and a.SourceSystemCustomerID is not null

				/*UPDATE DEG DATE AND FLAG FOR THE UCIF ID UNDER NPA CRITERIA*/
				UPDATE A
					 SET A.DegDate=SysNPA_Dt
						,A.FlgDeg='Y'
						,A.Co_Assetclassalt_key=SysAssetClassAlt_Key
						,A.Co_NPADate=SysNPA_Dt
				FROM Pro.CoBorrowerDetails A 
					INNER JOIN #CUST_SELF_NPA B
						ON A.RefCustomerID=B.RefCustomerID
						--AND (A.EffectiveFromTimeKey<=@TIMEKEY and a.EffectiveToTimeKey>=@TIMEKEY)
					INNER JOIN Pro.CustomerCal c
						ON A.UCIF_ID=C.UCIF_ID
						--AND isnull(c.TotOsCust,0)>0
					WHERE ISNULL(A.FlgDeg,'N')='N' AND A.UCIF_ID IS NOT NULL

	
				/*UPDATE DEG DATE AND FLAG FOR THE PANNO UNDER NPA CRITERIA*/
				UPDATE A
					 SET A.DegDate=SysNPA_Dt
						,A.FlgDeg='Y'
						,A.Co_Assetclassalt_key=SysAssetClassAlt_Key
						,A.Co_NPADate=SysNPA_Dt
				FROM Pro.CoBorrowerDetails A 
					INNER JOIN #CUST_SELF_NPA B
						ON A.RefCustomerID=B.RefCustomerID
						--AND (A.EffectiveFromTimeKey<=@TIMEKEY and a.EffectiveToTimeKey>=@TIMEKEY)
					INNER JOIN Pro.CustomerCal c
						ON A.PANNO=C.PANNO
						--AND isnull(c.TotOsCust,0)>0
					WHERE ISNULL(A.FlgDeg,'N')='N' AND A.PANNO IS NOT NULL




		END

GO
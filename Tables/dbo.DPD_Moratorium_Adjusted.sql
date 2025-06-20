﻿CREATE TABLE [dbo].[DPD_Moratorium_Adjusted] (
  [EntityKey] [int] IDENTITY,
  [BranchCode] [varchar](20) NULL,
  [UCIF_ID] [varchar](50) NULL,
  [UcifEntityID] [int] NULL,
  [RefCustomerID] [varchar](50) NULL,
  [SourceSystemCustomerID] [varchar](50) NULL,
  [CustomerAcID] [varchar](30) NULL,
  [AccountEntityID] [int] NULL,
  [SourceAlt_Key] [tinyint] NULL,
  [FacilityType] [varchar](10) NULL,
  [Frozen_ContiExcessDt] [date] NULL,
  [Actual_ContiExcessDt] [date] NULL,
  [Adjusted_ContiExcessDt] [date] NULL,
  [Frozen_DPD_ContiExcessDt] [int] NULL,
  [Actual_DPD_ContiExcessDt] [int] NULL,
  [Adjusted_DPD_ContiExcessDt] [int] NULL,
  [Frozen_StockStDt] [date] NULL,
  [Actual_StockStDt] [date] NULL,
  [Adjusted_StockStDt] [date] NULL,
  [Frozen_DPD_StockStDt] [int] NULL,
  [Actual_DPD_StockStDt] [int] NULL,
  [Adjusted_DPD_StockStDt] [int] NULL,
  [Frozen_ReviewDueDt] [date] NULL,
  [Actual_ReviewDueDt] [date] NULL,
  [Adjusted_ReviewDueDt] [date] NULL,
  [Frozen_DPD_ReviewDueDt] [int] NULL,
  [Actual_DPD_ReviewDueDt] [int] NULL,
  [Adjusted_DPD_ReviewDueDt] [int] NULL,
  [Frozen_IntNotServicedDt] [date] NULL,
  [Actual_IntNotServicedDt] [date] NULL,
  [Adjusted_IntNotServicedDt] [date] NULL,
  [Frozen_DPD_IntNotServicedDt] [int] NULL,
  [Actual_DPD_IntNotServicedDt] [int] NULL,
  [Adjusted_DPD_IntNotServicedDt] [int] NULL,
  [Frozen_OverDueSinceDt] [date] NULL,
  [Actual_OverDueSinceDt] [date] NULL,
  [Adjusted_OverDueSinceDt] [date] NULL,
  [Frozen_DPD_OverDueSinceDt] [int] NULL,
  [Actual_DPD_OverDueSinceDt] [int] NULL,
  [Adjusted_DPD_OverDueSinceDt] [int] NULL,
  [Exclusion] [char](1) NULL,
  [TimeKey] [int] NULL,
  [FinalAssetClassAlt_Key] [int] NULL
)
ON [PRIMARY]
GO
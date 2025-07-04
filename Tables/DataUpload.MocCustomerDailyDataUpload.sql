﻿CREATE TABLE [DataUpload].[MocCustomerDailyDataUpload] (
  [Entitykey] [int] IDENTITY,
  [MocCustomerDataEntityId] [int] NULL,
  [CustomerID] [varchar](50) NULL,
  [CustomerName] [varchar](225) NULL,
  [AssetClassification] [varchar](20) NULL,
  [NPADate] [date] NULL,
  [MOCReason] [varchar](500) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp],
  [ScreenFlag] [char](1) NULL,
  [MOCTYPE] [varchar](15) NULL DEFAULT ('AUTO'),
  [DbtDt] [date] NULL
)
ON [PRIMARY]
GO
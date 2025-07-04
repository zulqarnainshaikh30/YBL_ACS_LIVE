﻿CREATE TABLE [DataUpload].[ReviewRenewalDataUpload] (
  [Entitykey] [int] IDENTITY,
  [ReviewDataEntityId] [int] NULL,
  [CustomerAcID] [varchar](30) NULL,
  [CustomerID] [varchar](50) NULL,
  [CustomerName] [varchar](225) NULL,
  [ReviewDate] [date] NULL,
  [ReviewExpiryDate] [date] NULL,
  [FacilityType] [nvarchar](200) NULL,
  [Remarks] [nvarchar](500) NULL,
  [AuthorisationStatus] [varchar](2) NULL,
  [EffectiveFromTimeKey] [int] NULL,
  [EffectiveToTimeKey] [int] NULL,
  [CreatedBy] [varchar](20) NULL,
  [DateCreated] [smalldatetime] NULL,
  [ModifiedBy] [varchar](20) NULL,
  [DateModified] [smalldatetime] NULL,
  [ApprovedBy] [varchar](20) NULL,
  [DateApproved] [smalldatetime] NULL,
  [D2Ktimestamp] [timestamp]
)
ON [PRIMARY]
GO
﻿CREATE TABLE [dbo].[AbsoluteProvisionMOC_Final] (
  [AccountEntityID] [varchar](30) NULL,
  [UCIF_ID] [varchar](30) NULL,
  [CustomerID] [varchar](30) NULL,
  [SourceSystemCustomerID] [varchar](30) NULL,
  [BranchCode] [varchar](30) NULL,
  [OriginalProvision] [varchar](30) NULL,
  [NetBalance] [varchar](30) NULL,
  [CustomerACID] [varchar](30) NULL,
  [ExistingProvision] [varchar](30) NULL,
  [AdditionalProvision] [varchar](30) NULL,
  [FinalProvision] [varchar](30) NULL,
  [MOCREASON] [varchar](500) NULL,
  [AbsProvMOCEntityId] [int] NULL,
  [FILENAME] [varchar](max) NULL,
  [UserLoginId] [varchar](20) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO
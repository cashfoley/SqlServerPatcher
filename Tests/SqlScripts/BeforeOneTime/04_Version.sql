/****** Object:  Table [dbo].[Version]    Script Date: 12/21/2015 2:02:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Version](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[repository_path] [nvarchar](255) NULL,
	[version] [nvarchar](50) NULL,
	[entry_date] [datetime] NULL,
	[modified_date] [datetime] NULL,
	[entered_by] [nvarchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

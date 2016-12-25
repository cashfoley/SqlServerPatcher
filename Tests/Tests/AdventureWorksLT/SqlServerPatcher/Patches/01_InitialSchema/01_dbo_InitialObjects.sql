PRINT N'Creating [SalesLT]...';


GO
CREATE SCHEMA [SalesLT]
    AUTHORIZATION [dbo];


GO
PRINT N'Creating [dbo].[AccountNumber]...';


GO
CREATE TYPE [dbo].[AccountNumber]
    FROM NVARCHAR (15) NULL;


GO
PRINT N'Creating [dbo].[Flag]...';


GO
CREATE TYPE [dbo].[Flag]
    FROM BIT NOT NULL;


GO
PRINT N'Creating [dbo].[Name]...';


GO
CREATE TYPE [dbo].[Name]
    FROM NVARCHAR (50) NULL;


GO
PRINT N'Creating [dbo].[NameStyle]...';


GO
CREATE TYPE [dbo].[NameStyle]
    FROM BIT NOT NULL;


GO
PRINT N'Creating [dbo].[OrderNumber]...';


GO
CREATE TYPE [dbo].[OrderNumber]
    FROM NVARCHAR (25) NULL;


GO
PRINT N'Creating [dbo].[Phone]...';


GO
CREATE TYPE [dbo].[Phone]
    FROM NVARCHAR (25) NULL;


GO
PRINT N'Creating [SalesLT].[ProductCategory]...';


GO
CREATE TABLE [SalesLT].[ProductCategory] (
    [ProductCategoryID]       INT              IDENTITY (1, 1) NOT NULL,
    [ParentProductCategoryID] INT              NULL,
    [Name]                    [dbo].[Name]     NOT NULL,
    [rowguid]                 UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]            DATETIME         NOT NULL,
    CONSTRAINT [PK_ProductCategory_ProductCategoryID] PRIMARY KEY CLUSTERED ([ProductCategoryID] ASC),
    CONSTRAINT [AK_ProductCategory_Name] UNIQUE NONCLUSTERED ([Name] ASC),
    CONSTRAINT [AK_ProductCategory_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[Customer]...';


GO
CREATE TABLE [SalesLT].[Customer] (
    [CustomerID]   INT               IDENTITY (1, 1) NOT NULL,
    [NameStyle]    [dbo].[NameStyle] NOT NULL,
    [Title]        NVARCHAR (8)      NULL,
    [FirstName]    [dbo].[Name]      NOT NULL,
    [MiddleName]   [dbo].[Name]      NULL,
    [LastName]     [dbo].[Name]      NOT NULL,
    [Suffix]       NVARCHAR (10)     NULL,
    [CompanyName]  NVARCHAR (128)    NULL,
    [SalesPerson]  NVARCHAR (256)    NULL,
    [EmailAddress] NVARCHAR (50)     NULL,
    [Phone]        [dbo].[Phone]     NULL,
    [PasswordHash] VARCHAR (128)     NOT NULL,
    [PasswordSalt] VARCHAR (10)      NOT NULL,
    [rowguid]      UNIQUEIDENTIFIER  NOT NULL,
    [ModifiedDate] DATETIME          NOT NULL,
    CONSTRAINT [PK_Customer_CustomerID] PRIMARY KEY CLUSTERED ([CustomerID] ASC),
    CONSTRAINT [AK_Customer_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [dbo].[BuildVersion]...';


GO
CREATE TABLE [dbo].[BuildVersion] (
    [SystemInformationID] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Database Version]    NVARCHAR (25) NOT NULL,
    [VersionDate]         DATETIME      NOT NULL,
    [ModifiedDate]        DATETIME      NOT NULL,
    PRIMARY KEY CLUSTERED ([SystemInformationID] ASC)
);


GO
PRINT N'Creating [dbo].[ErrorLog]...';


GO
CREATE TABLE [dbo].[ErrorLog] (
    [ErrorLogID]     INT             IDENTITY (1, 1) NOT NULL,
    [ErrorTime]      DATETIME        NOT NULL,
    [UserName]       [sysname]       NOT NULL,
    [ErrorNumber]    INT             NOT NULL,
    [ErrorSeverity]  INT             NULL,
    [ErrorState]     INT             NULL,
    [ErrorProcedure] NVARCHAR (126)  NULL,
    [ErrorLine]      INT             NULL,
    [ErrorMessage]   NVARCHAR (4000) NOT NULL,
    CONSTRAINT [PK_ErrorLog_ErrorLogID] PRIMARY KEY CLUSTERED ([ErrorLogID] ASC)
);


GO
PRINT N'Creating [dbo].[DF_BuildVersion_ModifiedDate]...';


GO
ALTER TABLE [dbo].[BuildVersion]
    ADD CONSTRAINT [DF_BuildVersion_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [dbo].[DF_ErrorLog_ErrorTime]...';


GO
ALTER TABLE [dbo].[ErrorLog]
    ADD CONSTRAINT [DF_ErrorLog_ErrorTime] DEFAULT (getdate()) FOR [ErrorTime];


GO
PRINT N'Creating [dbo].[ufnGetSalesOrderStatusText]...';


GO
CREATE FUNCTION [dbo].[ufnGetSalesOrderStatusText](@Status tinyint)
RETURNS nvarchar(15)
AS
-- Returns the sales order status text representation for the status value.
BEGIN
    DECLARE @ret nvarchar(15);

    SET @ret =
        CASE @Status
            WHEN 1 THEN 'In process'
            WHEN 2 THEN 'Approved'
            WHEN 3 THEN 'Backordered'
            WHEN 4 THEN 'Rejected'
            WHEN 5 THEN 'Shipped'
            WHEN 6 THEN 'Cancelled'
            ELSE '** Invalid **'
        END;

    RETURN @ret
END;
GO
PRINT N'Creating [dbo].[ufnGetCustomerInformation]...';


GO
CREATE FUNCTION [dbo].[ufnGetCustomerInformation](@CustomerID int)
RETURNS TABLE
AS
-- Returns the CustomerID, first name, and last name for the specified customer.
RETURN (
    SELECT
        CustomerID,
        FirstName,
        LastName
    FROM [SalesLT].[Customer]
    WHERE [CustomerID] = @CustomerID
);
GO
PRINT N'Creating [dbo].[ufnGetAllCategories]...';


GO
CREATE FUNCTION [dbo].[ufnGetAllCategories]()
RETURNS @retCategoryInformation TABLE
(
    -- Columns returned by the function
    [ParentProductCategoryName] nvarchar(50) NULL,
    [ProductCategoryName] nvarchar(50) NOT NULL,
    [ProductCategoryID] int NOT NULL
)
AS
-- Returns the CustomerID, first name, and last name for the specified customer.
BEGIN
    WITH CategoryCTE([ParentProductCategoryID], [ProductCategoryID], [Name]) AS
    (
        SELECT [ParentProductCategoryID], [ProductCategoryID], [Name]
        FROM SalesLT.ProductCategory
        WHERE ParentProductCategoryID IS NULL

    UNION ALL

        SELECT C.[ParentProductCategoryID], C.[ProductCategoryID], C.[Name]
        FROM SalesLT.ProductCategory AS C
        INNER JOIN CategoryCTE AS BC ON BC.ProductCategoryID = C.ParentProductCategoryID
    )

    INSERT INTO @retCategoryInformation
    SELECT PC.[Name] AS [ParentProductCategoryName], CCTE.[Name] as [ProductCategoryName], CCTE.[ProductCategoryID]
    FROM CategoryCTE AS CCTE
    JOIN SalesLT.ProductCategory AS PC
    ON PC.[ProductCategoryID] = CCTE.[ParentProductCategoryID];
    RETURN;
END;
GO
PRINT N'Creating [dbo].[uspPrintError]...';


GO

-- uspPrintError prints error information about the error that caused
-- execution to jump to the CATCH block of a TRY...CATCH construct.
-- Should be executed from within the scope of a CATCH block otherwise
-- it will return without printing any error information.
CREATE PROCEDURE [dbo].[uspPrintError]
AS
BEGIN
    SET NOCOUNT ON;

    -- Print error information.
    PRINT 'Error ' + CONVERT(varchar(50), ERROR_NUMBER()) +
          ', Severity ' + CONVERT(varchar(5), ERROR_SEVERITY()) +
          ', State ' + CONVERT(varchar(5), ERROR_STATE()) +
          ', Procedure ' + ISNULL(ERROR_PROCEDURE(), '-') +
          ', Line ' + CONVERT(varchar(5), ERROR_LINE());
    PRINT ERROR_MESSAGE();
END;
GO
PRINT N'Creating [dbo].[uspLogError]...';


GO

-- uspLogError logs error information in the ErrorLog table about the
-- error that caused execution to jump to the CATCH block of a
-- TRY...CATCH construct. This should be executed from within the scope
-- of a CATCH block otherwise it will return without inserting error
-- information.
CREATE PROCEDURE [dbo].[uspLogError]
    @ErrorLogID int = 0 OUTPUT -- contains the ErrorLogID of the row inserted
AS                             -- by uspLogError in the ErrorLog table
BEGIN
    SET NOCOUNT ON;

    -- Output parameter value of 0 indicates that error
    -- information was not logged
    SET @ErrorLogID = 0;

    BEGIN TRY
        -- Return if there is no error information to log
        IF ERROR_NUMBER() IS NULL
            RETURN;

        -- Return if inside an uncommittable transaction.
        -- Data insertion/modification is not allowed when
        -- a transaction is in an uncommittable state.
        IF XACT_STATE() = -1
        BEGIN
            PRINT 'Cannot log error since the current transaction is in an uncommittable state. '
                + 'Rollback the transaction before executing uspLogError in order to successfully log error information.';
            RETURN;
        END

        INSERT [dbo].[ErrorLog]
            (
            [UserName],
            [ErrorNumber],
            [ErrorSeverity],
            [ErrorState],
            [ErrorProcedure],
            [ErrorLine],
            [ErrorMessage]
            )
        VALUES
            (
            CONVERT(sysname, CURRENT_USER),
            ERROR_NUMBER(),
            ERROR_SEVERITY(),
            ERROR_STATE(),
            ERROR_PROCEDURE(),
            ERROR_LINE(),
            ERROR_MESSAGE()
            );

        -- Pass back the ErrorLogID of the row inserted
        SET @ErrorLogID = @@IDENTITY;
    END TRY
    BEGIN CATCH
        PRINT 'An error occurred in stored procedure uspLogError: ';
        EXECUTE [dbo].[uspPrintError];
        RETURN -1;
    END CATCH
END;
GO
PRINT N'Update complete.';


GO

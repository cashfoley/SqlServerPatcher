
PRINT N'Creating [SalesLT]...';


GO
CREATE SCHEMA [SalesLT]
    AUTHORIZATION [dbo];


GO
PRINT N'Creating [SalesLT].[SalesOrderHeader]...';


GO
CREATE TABLE [SalesLT].[SalesOrderHeader] (
    [SalesOrderID]           INT                   NOT NULL,
    [RevisionNumber]         TINYINT               NOT NULL,
    [OrderDate]              DATETIME              NOT NULL,
    [DueDate]                DATETIME              NOT NULL,
    [ShipDate]               DATETIME              NULL,
    [Status]                 TINYINT               NOT NULL,
    [OnlineOrderFlag]        [dbo].[Flag]          NOT NULL,
    [SalesOrderNumber]       AS                    (isnull(N'SO' + CONVERT (NVARCHAR (23), [SalesOrderID], (0)), N'*** ERROR ***')),
    [PurchaseOrderNumber]    [dbo].[OrderNumber]   NULL,
    [AccountNumber]          [dbo].[AccountNumber] NULL,
    [CustomerID]             INT                   NOT NULL,
    [ShipToAddressID]        INT                   NULL,
    [BillToAddressID]        INT                   NULL,
    [ShipMethod]             NVARCHAR (50)         NOT NULL,
    [CreditCardApprovalCode] VARCHAR (15)          NULL,
    [SubTotal]               MONEY                 NOT NULL,
    [TaxAmt]                 MONEY                 NOT NULL,
    [Freight]                MONEY                 NOT NULL,
    [TotalDue]               AS                    (isnull(([SubTotal] + [TaxAmt]) + [Freight], (0))),
    [Comment]                NVARCHAR (MAX)        NULL,
    [rowguid]                UNIQUEIDENTIFIER      NOT NULL,
    [ModifiedDate]           DATETIME              NOT NULL,
    CONSTRAINT [PK_SalesOrderHeader_SalesOrderID] PRIMARY KEY CLUSTERED ([SalesOrderID] ASC),
    CONSTRAINT [AK_SalesOrderHeader_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC),
    CONSTRAINT [AK_SalesOrderHeader_SalesOrderNumber] UNIQUE NONCLUSTERED ([SalesOrderNumber] ASC)
);


GO
PRINT N'Creating [SalesLT].[SalesOrderHeader].[IX_SalesOrderHeader_CustomerID]...';


GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderHeader_CustomerID]
    ON [SalesLT].[SalesOrderHeader]([CustomerID] ASC);


GO
PRINT N'Creating [SalesLT].[SalesOrderDetail]...';


GO
CREATE TABLE [SalesLT].[SalesOrderDetail] (
    [SalesOrderID]       INT              NOT NULL,
    [SalesOrderDetailID] INT              IDENTITY (1, 1) NOT NULL,
    [OrderQty]           SMALLINT         NOT NULL,
    [ProductID]          INT              NOT NULL,
    [UnitPrice]          MONEY            NOT NULL,
    [UnitPriceDiscount]  MONEY            NOT NULL,
    [LineTotal]          AS               (isnull(([UnitPrice] * ((1.0) - [UnitPriceDiscount])) * [OrderQty], (0.0))),
    [rowguid]            UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]       DATETIME         NOT NULL,
    CONSTRAINT [PK_SalesOrderDetail_SalesOrderID_SalesOrderDetailID] PRIMARY KEY CLUSTERED ([SalesOrderID] ASC, [SalesOrderDetailID] ASC),
    CONSTRAINT [AK_SalesOrderDetail_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[SalesOrderDetail].[IX_SalesOrderDetail_ProductID]...';


GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_ProductID]
    ON [SalesLT].[SalesOrderDetail]([ProductID] ASC);


GO
PRINT N'Creating [SalesLT].[CustomerAddress]...';


GO
CREATE TABLE [SalesLT].[CustomerAddress] (
    [CustomerID]   INT              NOT NULL,
    [AddressID]    INT              NOT NULL,
    [AddressType]  [dbo].[Name]     NOT NULL,
    [rowguid]      UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate] DATETIME         NOT NULL,
    CONSTRAINT [PK_CustomerAddress_CustomerID_AddressID] PRIMARY KEY CLUSTERED ([CustomerID] ASC, [AddressID] ASC),
    CONSTRAINT [AK_CustomerAddress_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[Address]...';


GO
CREATE TABLE [SalesLT].[Address] (
    [AddressID]     INT              IDENTITY (1, 1) NOT NULL,
    [AddressLine1]  NVARCHAR (60)    NOT NULL,
    [AddressLine2]  NVARCHAR (60)    NULL,
    [City]          NVARCHAR (30)    NOT NULL,
    [StateProvince] [dbo].[Name]     NOT NULL,
    [CountryRegion] [dbo].[Name]     NOT NULL,
    [PostalCode]    NVARCHAR (15)    NOT NULL,
    [rowguid]       UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]  DATETIME         NOT NULL,
    CONSTRAINT [PK_Address_AddressID] PRIMARY KEY CLUSTERED ([AddressID] ASC),
    CONSTRAINT [AK_Address_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[Address].[IX_Address_StateProvince]...';


GO
CREATE NONCLUSTERED INDEX [IX_Address_StateProvince]
    ON [SalesLT].[Address]([StateProvince] ASC);


GO
PRINT N'Creating [SalesLT].[Address].[IX_Address_AddressLine1_AddressLine2_City_StateProvince_PostalCode_CountryRegion]...';


GO
CREATE NONCLUSTERED INDEX [IX_Address_AddressLine1_AddressLine2_City_StateProvince_PostalCode_CountryRegion]
    ON [SalesLT].[Address]([AddressLine1] ASC, [AddressLine2] ASC, [City] ASC, [StateProvince] ASC, [PostalCode] ASC, [CountryRegion] ASC);


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
PRINT N'Creating [SalesLT].[ProductModelProductDescription]...';


GO
CREATE TABLE [SalesLT].[ProductModelProductDescription] (
    [ProductModelID]       INT              NOT NULL,
    [ProductDescriptionID] INT              NOT NULL,
    [Culture]              NCHAR (6)        NOT NULL,
    [rowguid]              UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]         DATETIME         NOT NULL,
    CONSTRAINT [PK_ProductModelProductDescription_ProductModelID_ProductDescriptionID_Culture] PRIMARY KEY CLUSTERED ([ProductModelID] ASC, [ProductDescriptionID] ASC, [Culture] ASC),
    CONSTRAINT [AK_ProductModelProductDescription_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[Product]...';


GO
CREATE TABLE [SalesLT].[Product] (
    [ProductID]              INT              IDENTITY (1, 1) NOT NULL,
    [Name]                   [dbo].[Name]     NOT NULL,
    [ProductNumber]          NVARCHAR (25)    NOT NULL,
    [Color]                  NVARCHAR (15)    NULL,
    [StandardCost]           MONEY            NOT NULL,
    [ListPrice]              MONEY            NOT NULL,
    [Size]                   NVARCHAR (5)     NULL,
    [Weight]                 DECIMAL (8, 2)   NULL,
    [ProductCategoryID]      INT              NULL,
    [ProductModelID]         INT              NULL,
    [SellStartDate]          DATETIME         NOT NULL,
    [SellEndDate]            DATETIME         NULL,
    [DiscontinuedDate]       DATETIME         NULL,
    [ThumbNailPhoto]         VARBINARY (MAX)  NULL,
    [ThumbnailPhotoFileName] NVARCHAR (50)    NULL,
    [rowguid]                UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]           DATETIME         NOT NULL,
    CONSTRAINT [PK_Product_ProductID] PRIMARY KEY CLUSTERED ([ProductID] ASC),
    CONSTRAINT [AK_Product_Name] UNIQUE NONCLUSTERED ([Name] ASC),
    CONSTRAINT [AK_Product_ProductNumber] UNIQUE NONCLUSTERED ([ProductNumber] ASC),
    CONSTRAINT [AK_Product_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[ProductDescription]...';


GO
CREATE TABLE [SalesLT].[ProductDescription] (
    [ProductDescriptionID] INT              IDENTITY (1, 1) NOT NULL,
    [Description]          NVARCHAR (400)   NOT NULL,
    [rowguid]              UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]         DATETIME         NOT NULL,
    CONSTRAINT [PK_ProductDescription_ProductDescriptionID] PRIMARY KEY CLUSTERED ([ProductDescriptionID] ASC),
    CONSTRAINT [AK_ProductDescription_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
);


GO
PRINT N'Creating [SalesLT].[ProductModel]...';


GO
CREATE TABLE [SalesLT].[ProductModel] (
    [ProductModelID]     INT              IDENTITY (1, 1) NOT NULL,
    [Name]               [dbo].[Name]     NOT NULL,
    [CatalogDescription] XML              NULL,
    [rowguid]            UNIQUEIDENTIFIER NOT NULL,
    [ModifiedDate]       DATETIME         NOT NULL,
    CONSTRAINT [PK_ProductModel_ProductModelID] PRIMARY KEY CLUSTERED ([ProductModelID] ASC),
    CONSTRAINT [AK_ProductModel_Name] UNIQUE NONCLUSTERED ([Name] ASC),
    CONSTRAINT [AK_ProductModel_rowguid] UNIQUE NONCLUSTERED ([rowguid] ASC)
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
PRINT N'Creating [SalesLT].[Customer].[IX_Customer_EmailAddress]...';


GO
CREATE NONCLUSTERED INDEX [IX_Customer_EmailAddress]
    ON [SalesLT].[Customer]([EmailAddress] ASC);


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_RevisionNumber]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_RevisionNumber] DEFAULT ((0)) FOR [RevisionNumber];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_OrderDate]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_OrderDate] DEFAULT (getdate()) FOR [OrderDate];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_Status]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_Status] DEFAULT ((1)) FOR [Status];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_OnlineOrderFlag]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_OnlineOrderFlag] DEFAULT ((1)) FOR [OnlineOrderFlag];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_SubTotal]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_SubTotal] DEFAULT ((0.00)) FOR [SubTotal];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_TaxAmt]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_TaxAmt] DEFAULT ((0.00)) FOR [TaxAmt];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_Freight]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_Freight] DEFAULT ((0.00)) FOR [Freight];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_rowguid]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderDetail_UnitPriceDiscount]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail]
    ADD CONSTRAINT [DF_SalesOrderDetail_UnitPriceDiscount] DEFAULT ((0.0)) FOR [UnitPriceDiscount];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderDetail_rowguid]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail]
    ADD CONSTRAINT [DF_SalesOrderDetail_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderDetail_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail]
    ADD CONSTRAINT [DF_SalesOrderDetail_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_CustomerAddress_rowguid]...';


GO
ALTER TABLE [SalesLT].[CustomerAddress]
    ADD CONSTRAINT [DF_CustomerAddress_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_CustomerAddress_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[CustomerAddress]
    ADD CONSTRAINT [DF_CustomerAddress_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_Address_rowguid]...';


GO
ALTER TABLE [SalesLT].[Address]
    ADD CONSTRAINT [DF_Address_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_Address_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[Address]
    ADD CONSTRAINT [DF_Address_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_ProductCategory_rowguid]...';


GO
ALTER TABLE [SalesLT].[ProductCategory]
    ADD CONSTRAINT [DF_ProductCategory_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_ProductCategory_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[ProductCategory]
    ADD CONSTRAINT [DF_ProductCategory_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_ProductModelProductDescription_rowguid]...';


GO
ALTER TABLE [SalesLT].[ProductModelProductDescription]
    ADD CONSTRAINT [DF_ProductModelProductDescription_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_ProductModelProductDescription_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[ProductModelProductDescription]
    ADD CONSTRAINT [DF_ProductModelProductDescription_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_Product_rowguid]...';


GO
ALTER TABLE [SalesLT].[Product]
    ADD CONSTRAINT [DF_Product_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_Product_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[Product]
    ADD CONSTRAINT [DF_Product_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_ProductDescription_rowguid]...';


GO
ALTER TABLE [SalesLT].[ProductDescription]
    ADD CONSTRAINT [DF_ProductDescription_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_ProductDescription_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[ProductDescription]
    ADD CONSTRAINT [DF_ProductDescription_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_ProductModel_rowguid]...';


GO
ALTER TABLE [SalesLT].[ProductModel]
    ADD CONSTRAINT [DF_ProductModel_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_ProductModel_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[ProductModel]
    ADD CONSTRAINT [DF_ProductModel_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[DF_Customer_NameStyle]...';


GO
ALTER TABLE [SalesLT].[Customer]
    ADD CONSTRAINT [DF_Customer_NameStyle] DEFAULT ((0)) FOR [NameStyle];


GO
PRINT N'Creating [SalesLT].[DF_Customer_rowguid]...';


GO
ALTER TABLE [SalesLT].[Customer]
    ADD CONSTRAINT [DF_Customer_rowguid] DEFAULT (newid()) FOR [rowguid];


GO
PRINT N'Creating [SalesLT].[DF_Customer_ModifiedDate]...';


GO
ALTER TABLE [SalesLT].[Customer]
    ADD CONSTRAINT [DF_Customer_ModifiedDate] DEFAULT (getdate()) FOR [ModifiedDate];


GO
PRINT N'Creating [SalesLT].[SalesOrderNumber]...';


GO
CREATE SEQUENCE [SalesLT].[SalesOrderNumber]
    AS INT
    START WITH 1
    INCREMENT BY 1;


GO
PRINT N'Creating [SalesLT].[DF_SalesOrderHeader_OrderID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader]
    ADD CONSTRAINT [DF_SalesOrderHeader_OrderID] DEFAULT (NEXT VALUE FOR [SalesLT].[SalesOrderNumber]) FOR [SalesOrderID];


GO
PRINT N'Creating [SalesLT].[FK_SalesOrderHeader_Address_BillTo_AddressID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [FK_SalesOrderHeader_Address_BillTo_AddressID] FOREIGN KEY ([BillToAddressID]) REFERENCES [SalesLT].[Address] ([AddressID]);


GO
PRINT N'Creating [SalesLT].[FK_SalesOrderHeader_Address_ShipTo_AddressID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [FK_SalesOrderHeader_Address_ShipTo_AddressID] FOREIGN KEY ([ShipToAddressID]) REFERENCES [SalesLT].[Address] ([AddressID]);


GO
PRINT N'Creating [SalesLT].[FK_SalesOrderHeader_Customer_CustomerID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [FK_SalesOrderHeader_Customer_CustomerID] FOREIGN KEY ([CustomerID]) REFERENCES [SalesLT].[Customer] ([CustomerID]);


GO
PRINT N'Creating [SalesLT].[FK_SalesOrderDetail_Product_ProductID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail] WITH NOCHECK
    ADD CONSTRAINT [FK_SalesOrderDetail_Product_ProductID] FOREIGN KEY ([ProductID]) REFERENCES [SalesLT].[Product] ([ProductID]);


GO
PRINT N'Creating [SalesLT].[FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail] WITH NOCHECK
    ADD CONSTRAINT [FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID] FOREIGN KEY ([SalesOrderID]) REFERENCES [SalesLT].[SalesOrderHeader] ([SalesOrderID]) ON DELETE CASCADE;


GO
PRINT N'Creating [SalesLT].[FK_CustomerAddress_Address_AddressID]...';


GO
ALTER TABLE [SalesLT].[CustomerAddress] WITH NOCHECK
    ADD CONSTRAINT [FK_CustomerAddress_Address_AddressID] FOREIGN KEY ([AddressID]) REFERENCES [SalesLT].[Address] ([AddressID]);


GO
PRINT N'Creating [SalesLT].[FK_CustomerAddress_Customer_CustomerID]...';


GO
ALTER TABLE [SalesLT].[CustomerAddress] WITH NOCHECK
    ADD CONSTRAINT [FK_CustomerAddress_Customer_CustomerID] FOREIGN KEY ([CustomerID]) REFERENCES [SalesLT].[Customer] ([CustomerID]);


GO
PRINT N'Creating [SalesLT].[FK_ProductCategory_ProductCategory_ParentProductCategoryID_ProductCategoryID]...';


GO
ALTER TABLE [SalesLT].[ProductCategory] WITH NOCHECK
    ADD CONSTRAINT [FK_ProductCategory_ProductCategory_ParentProductCategoryID_ProductCategoryID] FOREIGN KEY ([ParentProductCategoryID]) REFERENCES [SalesLT].[ProductCategory] ([ProductCategoryID]);


GO
PRINT N'Creating [SalesLT].[FK_ProductModelProductDescription_ProductDescription_ProductDescriptionID]...';


GO
ALTER TABLE [SalesLT].[ProductModelProductDescription] WITH NOCHECK
    ADD CONSTRAINT [FK_ProductModelProductDescription_ProductDescription_ProductDescriptionID] FOREIGN KEY ([ProductDescriptionID]) REFERENCES [SalesLT].[ProductDescription] ([ProductDescriptionID]);


GO
PRINT N'Creating [SalesLT].[FK_ProductModelProductDescription_ProductModel_ProductModelID]...';


GO
ALTER TABLE [SalesLT].[ProductModelProductDescription] WITH NOCHECK
    ADD CONSTRAINT [FK_ProductModelProductDescription_ProductModel_ProductModelID] FOREIGN KEY ([ProductModelID]) REFERENCES [SalesLT].[ProductModel] ([ProductModelID]);


GO
PRINT N'Creating [SalesLT].[FK_Product_ProductCategory_ProductCategoryID]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [FK_Product_ProductCategory_ProductCategoryID] FOREIGN KEY ([ProductCategoryID]) REFERENCES [SalesLT].[ProductCategory] ([ProductCategoryID]);


GO
PRINT N'Creating [SalesLT].[FK_Product_ProductModel_ProductModelID]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [FK_Product_ProductModel_ProductModelID] FOREIGN KEY ([ProductModelID]) REFERENCES [SalesLT].[ProductModel] ([ProductModelID]);


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_DueDate]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_DueDate] CHECK ([DueDate]>=[OrderDate]);


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_Freight]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_Freight] CHECK ([Freight]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_ShipDate]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_ShipDate] CHECK ([ShipDate]>=[OrderDate] OR [ShipDate] IS NULL);


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_Status]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_Status] CHECK ([Status]>=(0) AND [Status]<=(8));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_SubTotal]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_SubTotal] CHECK ([SubTotal]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderHeader_TaxAmt]...';


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderHeader_TaxAmt] CHECK ([TaxAmt]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderDetail_OrderQty]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderDetail_OrderQty] CHECK ([OrderQty]>(0));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderDetail_UnitPrice]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderDetail_UnitPrice] CHECK ([UnitPrice]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_SalesOrderDetail_UnitPriceDiscount]...';


GO
ALTER TABLE [SalesLT].[SalesOrderDetail] WITH NOCHECK
    ADD CONSTRAINT [CK_SalesOrderDetail_UnitPriceDiscount] CHECK ([UnitPriceDiscount]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_Product_ListPrice]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [CK_Product_ListPrice] CHECK ([ListPrice]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_Product_SellEndDate]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [CK_Product_SellEndDate] CHECK ([SellEndDate]>=[SellStartDate] OR [SellEndDate] IS NULL);


GO
PRINT N'Creating [SalesLT].[CK_Product_StandardCost]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [CK_Product_StandardCost] CHECK ([StandardCost]>=(0.00));


GO
PRINT N'Creating [SalesLT].[CK_Product_Weight]...';


GO
ALTER TABLE [SalesLT].[Product] WITH NOCHECK
    ADD CONSTRAINT [CK_Product_Weight] CHECK ([Weight]>(0.00));


GO
PRINT N'Creating [SalesLT].[vGetAllCategories]...';


GO
CREATE VIEW [SalesLT].[vGetAllCategories]
WITH SCHEMABINDING
AS
-- Returns the CustomerID, first name, and last name for the specified customer.
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

SELECT PC.[Name] AS [ParentProductCategoryName], CCTE.[Name] as [ProductCategoryName], CCTE.[ProductCategoryID]
FROM CategoryCTE AS CCTE
JOIN SalesLT.ProductCategory AS PC
ON PC.[ProductCategoryID] = CCTE.[ParentProductCategoryID]
GO
PRINT N'Creating [SalesLT].[vProductAndDescription]...';


GO
CREATE VIEW [SalesLT].[vProductAndDescription]
WITH SCHEMABINDING
AS
-- View (indexed or standard) to display products and product descriptions by language.
SELECT
    p.[ProductID]
    ,p.[Name]
    ,pm.[Name] AS [ProductModel]
    ,pmx.[Culture]
    ,pd.[Description]
FROM [SalesLT].[Product] p
    INNER JOIN [SalesLT].[ProductModel] pm
    ON p.[ProductModelID] = pm.[ProductModelID]
    INNER JOIN [SalesLT].[ProductModelProductDescription] pmx
    ON pm.[ProductModelID] = pmx.[ProductModelID]
    INNER JOIN [SalesLT].[ProductDescription] pd
    ON pmx.[ProductDescriptionID] = pd.[ProductDescriptionID];
GO
PRINT N'Creating [SalesLT].[vProductAndDescription].[IX_vProductAndDescription]...';


GO
CREATE UNIQUE CLUSTERED INDEX [IX_vProductAndDescription]
    ON [SalesLT].[vProductAndDescription]([Culture] ASC, [ProductID] ASC);


GO
PRINT N'Creating [SalesLT].[vProductModelCatalogDescription]...';


GO
CREATE VIEW [SalesLT].[vProductModelCatalogDescription]
AS
SELECT
    [ProductModelID]
    ,[Name]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace html="http://www.w3.org/1999/xhtml";
        (/p1:ProductDescription/p1:Summary/html:p)[1]', 'nvarchar(max)') AS [Summary]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Manufacturer/p1:Name)[1]', 'nvarchar(max)') AS [Manufacturer]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Manufacturer/p1:Copyright)[1]', 'nvarchar(30)') AS [Copyright]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Manufacturer/p1:ProductURL)[1]', 'nvarchar(256)') AS [ProductURL]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wm="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain";
        (/p1:ProductDescription/p1:Features/wm:Warranty/wm:WarrantyPeriod)[1]', 'nvarchar(256)') AS [WarrantyPeriod]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wm="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain";
        (/p1:ProductDescription/p1:Features/wm:Warranty/wm:Description)[1]', 'nvarchar(256)') AS [WarrantyDescription]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wm="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain";
        (/p1:ProductDescription/p1:Features/wm:Maintenance/wm:NoOfYears)[1]', 'nvarchar(256)') AS [NoOfYears]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wm="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelWarrAndMain";
        (/p1:ProductDescription/p1:Features/wm:Maintenance/wm:Description)[1]', 'nvarchar(256)') AS [MaintenanceDescription]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wf="http://www.adventure-works.com/schemas/OtherFeatures";
        (/p1:ProductDescription/p1:Features/wf:wheel)[1]', 'nvarchar(256)') AS [Wheel]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wf="http://www.adventure-works.com/schemas/OtherFeatures";
        (/p1:ProductDescription/p1:Features/wf:saddle)[1]', 'nvarchar(256)') AS [Saddle]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wf="http://www.adventure-works.com/schemas/OtherFeatures";
        (/p1:ProductDescription/p1:Features/wf:pedal)[1]', 'nvarchar(256)') AS [Pedal]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wf="http://www.adventure-works.com/schemas/OtherFeatures";
        (/p1:ProductDescription/p1:Features/wf:BikeFrame)[1]', 'nvarchar(max)') AS [BikeFrame]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        declare namespace wf="http://www.adventure-works.com/schemas/OtherFeatures";
        (/p1:ProductDescription/p1:Features/wf:crankset)[1]', 'nvarchar(256)') AS [Crankset]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Picture/p1:Angle)[1]', 'nvarchar(256)') AS [PictureAngle]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Picture/p1:Size)[1]', 'nvarchar(256)') AS [PictureSize]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Picture/p1:ProductPhotoID)[1]', 'nvarchar(256)') AS [ProductPhotoID]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Specifications/Material)[1]', 'nvarchar(256)') AS [Material]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Specifications/Color)[1]', 'nvarchar(256)') AS [Color]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Specifications/ProductLine)[1]', 'nvarchar(256)') AS [ProductLine]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Specifications/Style)[1]', 'nvarchar(256)') AS [Style]
    ,[CatalogDescription].value(N'declare namespace p1="http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelDescription";
        (/p1:ProductDescription/p1:Specifications/RiderExperience)[1]', 'nvarchar(1024)') AS [RiderExperience]
    ,[rowguid]
    ,[ModifiedDate]
FROM [SalesLT].[ProductModel]
WHERE [CatalogDescription] IS NOT NULL;
GO
PRINT N'Checking existing data against newly created constraints';


GO
USE [$(DatabaseName)];


GO
ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [FK_SalesOrderHeader_Address_BillTo_AddressID];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [FK_SalesOrderHeader_Address_ShipTo_AddressID];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [FK_SalesOrderHeader_Customer_CustomerID];

ALTER TABLE [SalesLT].[SalesOrderDetail] WITH CHECK CHECK CONSTRAINT [FK_SalesOrderDetail_Product_ProductID];

ALTER TABLE [SalesLT].[SalesOrderDetail] WITH CHECK CHECK CONSTRAINT [FK_SalesOrderDetail_SalesOrderHeader_SalesOrderID];

ALTER TABLE [SalesLT].[CustomerAddress] WITH CHECK CHECK CONSTRAINT [FK_CustomerAddress_Address_AddressID];

ALTER TABLE [SalesLT].[CustomerAddress] WITH CHECK CHECK CONSTRAINT [FK_CustomerAddress_Customer_CustomerID];

ALTER TABLE [SalesLT].[ProductCategory] WITH CHECK CHECK CONSTRAINT [FK_ProductCategory_ProductCategory_ParentProductCategoryID_ProductCategoryID];

ALTER TABLE [SalesLT].[ProductModelProductDescription] WITH CHECK CHECK CONSTRAINT [FK_ProductModelProductDescription_ProductDescription_ProductDescriptionID];

ALTER TABLE [SalesLT].[ProductModelProductDescription] WITH CHECK CHECK CONSTRAINT [FK_ProductModelProductDescription_ProductModel_ProductModelID];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [FK_Product_ProductCategory_ProductCategoryID];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [FK_Product_ProductModel_ProductModelID];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_DueDate];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_Freight];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_ShipDate];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_Status];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_SubTotal];

ALTER TABLE [SalesLT].[SalesOrderHeader] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderHeader_TaxAmt];

ALTER TABLE [SalesLT].[SalesOrderDetail] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderDetail_OrderQty];

ALTER TABLE [SalesLT].[SalesOrderDetail] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderDetail_UnitPrice];

ALTER TABLE [SalesLT].[SalesOrderDetail] WITH CHECK CHECK CONSTRAINT [CK_SalesOrderDetail_UnitPriceDiscount];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [CK_Product_ListPrice];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [CK_Product_SellEndDate];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [CK_Product_StandardCost];

ALTER TABLE [SalesLT].[Product] WITH CHECK CHECK CONSTRAINT [CK_Product_Weight];


GO
PRINT N'Update complete.';


GO

PRINT N'Creating [dbo].[Categories]...';


GO
CREATE TABLE [dbo].[Categories] (
    [CategoryID]   INT           IDENTITY (1, 1) NOT NULL,
    [CategoryName] NVARCHAR (15) NOT NULL,
    [Description]  NTEXT         NULL,
    [Picture]      IMAGE         NULL,
    CONSTRAINT [PK_Categories] PRIMARY KEY CLUSTERED ([CategoryID] ASC)
);


GO
PRINT N'Creating [dbo].[Categories].[CategoryName]...';


GO
CREATE NONCLUSTERED INDEX [CategoryName]
    ON [dbo].[Categories]([CategoryName] ASC);


GO
PRINT N'Creating [dbo].[Contacts]...';


GO
CREATE TABLE [dbo].[Contacts] (
    [ContactID]    INT            IDENTITY (1, 1) NOT NULL,
    [ContactType]  NVARCHAR (50)  NULL,
    [CompanyName]  NVARCHAR (40)  NOT NULL,
    [ContactName]  NVARCHAR (30)  NULL,
    [ContactTitle] NVARCHAR (30)  NULL,
    [Address]      NVARCHAR (60)  NULL,
    [City]         NVARCHAR (15)  NULL,
    [Region]       NVARCHAR (15)  NULL,
    [PostalCode]   NVARCHAR (10)  NULL,
    [Country]      NVARCHAR (15)  NULL,
    [Phone]        NVARCHAR (24)  NULL,
    [Extension]    NVARCHAR (4)   NULL,
    [Fax]          NVARCHAR (24)  NULL,
    [HomePage]     NTEXT          NULL,
    [PhotoPath]    NVARCHAR (255) NULL,
    [Photo]        IMAGE          NULL,
    CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED ([ContactID] ASC)
);


GO
PRINT N'Creating [dbo].[CustomerCustomerDemo]...';


GO
CREATE TABLE [dbo].[CustomerCustomerDemo] (
    [CustomerID]     NCHAR (5)  NOT NULL,
    [CustomerTypeID] NCHAR (10) NOT NULL,
    CONSTRAINT [PK_CustomerCustomerDemo] PRIMARY KEY NONCLUSTERED ([CustomerID] ASC, [CustomerTypeID] ASC)
);


GO
PRINT N'Creating [dbo].[CustomerDemographics]...';


GO
CREATE TABLE [dbo].[CustomerDemographics] (
    [CustomerTypeID] NCHAR (10) NOT NULL,
    [CustomerDesc]   NTEXT      NULL,
    CONSTRAINT [PK_CustomerDemographics] PRIMARY KEY NONCLUSTERED ([CustomerTypeID] ASC)
);


GO
PRINT N'Creating [dbo].[Customers]...';


GO
CREATE TABLE [dbo].[Customers] (
    [CustomerID]   NCHAR (5)     NOT NULL,
    [CompanyName]  NVARCHAR (40) NOT NULL,
    [ContactName]  NVARCHAR (30) NULL,
    [ContactTitle] NVARCHAR (30) NULL,
    [Address]      NVARCHAR (60) NULL,
    [City]         NVARCHAR (15) NULL,
    [Region]       NVARCHAR (15) NULL,
    [PostalCode]   NVARCHAR (10) NULL,
    [Country]      NVARCHAR (15) NULL,
    [Phone]        NVARCHAR (24) NULL,
    [Fax]          NVARCHAR (24) NULL,
    CONSTRAINT [PK_Customers] PRIMARY KEY CLUSTERED ([CustomerID] ASC)
);


GO
PRINT N'Creating [dbo].[Customers].[City]...';


GO
CREATE NONCLUSTERED INDEX [City]
    ON [dbo].[Customers]([City] ASC);


GO
PRINT N'Creating [dbo].[Customers].[CompanyName]...';


GO
CREATE NONCLUSTERED INDEX [CompanyName]
    ON [dbo].[Customers]([CompanyName] ASC);


GO
PRINT N'Creating [dbo].[Customers].[PostalCode]...';


GO
CREATE NONCLUSTERED INDEX [PostalCode]
    ON [dbo].[Customers]([PostalCode] ASC);


GO
PRINT N'Creating [dbo].[Customers].[Region]...';


GO
CREATE NONCLUSTERED INDEX [Region]
    ON [dbo].[Customers]([Region] ASC);


GO
PRINT N'Creating [dbo].[Employees]...';


GO
CREATE TABLE [dbo].[Employees] (
    [EmployeeID]      INT            IDENTITY (1, 1) NOT NULL,
    [LastName]        NVARCHAR (20)  NOT NULL,
    [FirstName]       NVARCHAR (10)  NOT NULL,
    [Title]           NVARCHAR (30)  NULL,
    [TitleOfCourtesy] NVARCHAR (25)  NULL,
    [BirthDate]       DATETIME       NULL,
    [HireDate]        DATETIME       NULL,
    [Address]         NVARCHAR (60)  NULL,
    [City]            NVARCHAR (15)  NULL,
    [Region]          NVARCHAR (15)  NULL,
    [PostalCode]      NVARCHAR (10)  NULL,
    [Country]         NVARCHAR (15)  NULL,
    [HomePhone]       NVARCHAR (24)  NULL,
    [Extension]       NVARCHAR (4)   NULL,
    [Photo]           IMAGE          NULL,
    [Notes]           NTEXT          NULL,
    [ReportsTo]       INT            NULL,
    [PhotoPath]       NVARCHAR (255) NULL,
    CONSTRAINT [PK_Employees] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);


GO
PRINT N'Creating [dbo].[Employees].[LastName]...';


GO
CREATE NONCLUSTERED INDEX [LastName]
    ON [dbo].[Employees]([LastName] ASC);


GO
PRINT N'Creating [dbo].[Employees].[PostalCode]...';


GO
CREATE NONCLUSTERED INDEX [PostalCode]
    ON [dbo].[Employees]([PostalCode] ASC);


GO
PRINT N'Creating [dbo].[EmployeeTerritories]...';


GO
CREATE TABLE [dbo].[EmployeeTerritories] (
    [EmployeeID]  INT           NOT NULL,
    [TerritoryID] NVARCHAR (20) NOT NULL,
    CONSTRAINT [PK_EmployeeTerritories] PRIMARY KEY NONCLUSTERED ([EmployeeID] ASC, [TerritoryID] ASC)
);


GO
PRINT N'Creating [dbo].[Order Details]...';


GO
CREATE TABLE [dbo].[Order Details] (
    [OrderID]   INT      NOT NULL,
    [ProductID] INT      NOT NULL,
    [UnitPrice] MONEY    NOT NULL,
    [Quantity]  SMALLINT NOT NULL,
    [Discount]  REAL     NOT NULL,
    CONSTRAINT [PK_Order_Details] PRIMARY KEY CLUSTERED ([OrderID] ASC, [ProductID] ASC)
);


GO
PRINT N'Creating [dbo].[Order Details].[OrderID]...';


GO
CREATE NONCLUSTERED INDEX [OrderID]
    ON [dbo].[Order Details]([OrderID] ASC);


GO
PRINT N'Creating [dbo].[Order Details].[OrdersOrder_Details]...';


GO
CREATE NONCLUSTERED INDEX [OrdersOrder_Details]
    ON [dbo].[Order Details]([OrderID] ASC);


GO
PRINT N'Creating [dbo].[Order Details].[ProductID]...';


GO
CREATE NONCLUSTERED INDEX [ProductID]
    ON [dbo].[Order Details]([ProductID] ASC);


GO
PRINT N'Creating [dbo].[Order Details].[ProductsOrder_Details]...';


GO
CREATE NONCLUSTERED INDEX [ProductsOrder_Details]
    ON [dbo].[Order Details]([ProductID] ASC);


GO
PRINT N'Creating [dbo].[Orders]...';


GO
CREATE TABLE [dbo].[Orders] (
    [OrderID]        INT           IDENTITY (1, 1) NOT NULL,
    [CustomerID]     NCHAR (5)     NULL,
    [EmployeeID]     INT           NULL,
    [OrderDate]      DATETIME      NULL,
    [RequiredDate]   DATETIME      NULL,
    [ShippedDate]    DATETIME      NULL,
    [ShipVia]        INT           NULL,
    [Freight]        MONEY         NULL,
    [ShipName]       NVARCHAR (40) NULL,
    [ShipAddress]    NVARCHAR (60) NULL,
    [ShipCity]       NVARCHAR (15) NULL,
    [ShipRegion]     NVARCHAR (15) NULL,
    [ShipPostalCode] NVARCHAR (10) NULL,
    [ShipCountry]    NVARCHAR (15) NULL,
    CONSTRAINT [PK_Orders] PRIMARY KEY CLUSTERED ([OrderID] ASC)
);


GO
PRINT N'Creating [dbo].[Orders].[CustomerID]...';


GO
CREATE NONCLUSTERED INDEX [CustomerID]
    ON [dbo].[Orders]([CustomerID] ASC);


GO
PRINT N'Creating [dbo].[Orders].[CustomersOrders]...';


GO
CREATE NONCLUSTERED INDEX [CustomersOrders]
    ON [dbo].[Orders]([CustomerID] ASC);


GO
PRINT N'Creating [dbo].[Orders].[EmployeeID]...';


GO
CREATE NONCLUSTERED INDEX [EmployeeID]
    ON [dbo].[Orders]([EmployeeID] ASC);


GO
PRINT N'Creating [dbo].[Orders].[EmployeesOrders]...';


GO
CREATE NONCLUSTERED INDEX [EmployeesOrders]
    ON [dbo].[Orders]([EmployeeID] ASC);


GO
PRINT N'Creating [dbo].[Orders].[OrderDate]...';


GO
CREATE NONCLUSTERED INDEX [OrderDate]
    ON [dbo].[Orders]([OrderDate] ASC);


GO
PRINT N'Creating [dbo].[Orders].[ShippedDate]...';


GO
CREATE NONCLUSTERED INDEX [ShippedDate]
    ON [dbo].[Orders]([ShippedDate] ASC);


GO
PRINT N'Creating [dbo].[Orders].[ShippersOrders]...';


GO
CREATE NONCLUSTERED INDEX [ShippersOrders]
    ON [dbo].[Orders]([ShipVia] ASC);


GO
PRINT N'Creating [dbo].[Orders].[ShipPostalCode]...';


GO
CREATE NONCLUSTERED INDEX [ShipPostalCode]
    ON [dbo].[Orders]([ShipPostalCode] ASC);


GO
PRINT N'Creating [dbo].[Products]...';


GO
CREATE TABLE [dbo].[Products] (
    [ProductID]       INT           IDENTITY (1, 1) NOT NULL,
    [ProductName]     NVARCHAR (40) NOT NULL,
    [SupplierID]      INT           NULL,
    [CategoryID]      INT           NULL,
    [QuantityPerUnit] NVARCHAR (20) NULL,
    [UnitPrice]       MONEY         NULL,
    [UnitsInStock]    SMALLINT      NULL,
    [UnitsOnOrder]    SMALLINT      NULL,
    [ReorderLevel]    SMALLINT      NULL,
    [Discontinued]    BIT           NOT NULL,
    CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED ([ProductID] ASC)
);


GO
PRINT N'Creating [dbo].[Products].[CategoriesProducts]...';


GO
CREATE NONCLUSTERED INDEX [CategoriesProducts]
    ON [dbo].[Products]([CategoryID] ASC);


GO
PRINT N'Creating [dbo].[Products].[CategoryID]...';


GO
CREATE NONCLUSTERED INDEX [CategoryID]
    ON [dbo].[Products]([CategoryID] ASC);


GO
PRINT N'Creating [dbo].[Products].[ProductName]...';


GO
CREATE NONCLUSTERED INDEX [ProductName]
    ON [dbo].[Products]([ProductName] ASC);


GO
PRINT N'Creating [dbo].[Products].[SupplierID]...';


GO
CREATE NONCLUSTERED INDEX [SupplierID]
    ON [dbo].[Products]([SupplierID] ASC);


GO
PRINT N'Creating [dbo].[Products].[SuppliersProducts]...';


GO
CREATE NONCLUSTERED INDEX [SuppliersProducts]
    ON [dbo].[Products]([SupplierID] ASC);


GO
PRINT N'Creating [dbo].[Region]...';


GO
CREATE TABLE [dbo].[Region] (
    [RegionID]          INT        NOT NULL,
    [RegionDescription] NCHAR (50) NOT NULL,
    CONSTRAINT [PK_Region] PRIMARY KEY NONCLUSTERED ([RegionID] ASC)
);


GO
PRINT N'Creating [dbo].[Shippers]...';


GO
CREATE TABLE [dbo].[Shippers] (
    [ShipperID]   INT           IDENTITY (1, 1) NOT NULL,
    [CompanyName] NVARCHAR (40) NOT NULL,
    [Phone]       NVARCHAR (24) NULL,
    CONSTRAINT [PK_Shippers] PRIMARY KEY CLUSTERED ([ShipperID] ASC)
);


GO
PRINT N'Creating [dbo].[Suppliers]...';


GO
CREATE TABLE [dbo].[Suppliers] (
    [SupplierID]   INT           IDENTITY (1, 1) NOT NULL,
    [CompanyName]  NVARCHAR (40) NOT NULL,
    [ContactName]  NVARCHAR (30) NULL,
    [ContactTitle] NVARCHAR (30) NULL,
    [Address]      NVARCHAR (60) NULL,
    [City]         NVARCHAR (15) NULL,
    [Region]       NVARCHAR (15) NULL,
    [PostalCode]   NVARCHAR (10) NULL,
    [Country]      NVARCHAR (15) NULL,
    [Phone]        NVARCHAR (24) NULL,
    [Fax]          NVARCHAR (24) NULL,
    [HomePage]     NTEXT         NULL,
    CONSTRAINT [PK_Suppliers] PRIMARY KEY CLUSTERED ([SupplierID] ASC)
);


GO
PRINT N'Creating [dbo].[Suppliers].[CompanyName]...';


GO
CREATE NONCLUSTERED INDEX [CompanyName]
    ON [dbo].[Suppliers]([CompanyName] ASC);


GO
PRINT N'Creating [dbo].[Suppliers].[PostalCode]...';


GO
CREATE NONCLUSTERED INDEX [PostalCode]
    ON [dbo].[Suppliers]([PostalCode] ASC);


GO
PRINT N'Creating [dbo].[Territories]...';


GO
CREATE TABLE [dbo].[Territories] (
    [TerritoryID]          NVARCHAR (20) NOT NULL,
    [TerritoryDescription] NCHAR (50)    NOT NULL,
    [RegionID]             INT           NOT NULL,
    CONSTRAINT [PK_Territories] PRIMARY KEY NONCLUSTERED ([TerritoryID] ASC)
);


GO
PRINT N'Creating [dbo].[DF_Order_Details_UnitPrice]...';


GO
ALTER TABLE [dbo].[Order Details]
    ADD CONSTRAINT [DF_Order_Details_UnitPrice] DEFAULT (0) FOR [UnitPrice];


GO
PRINT N'Creating [dbo].[DF_Order_Details_Quantity]...';


GO
ALTER TABLE [dbo].[Order Details]
    ADD CONSTRAINT [DF_Order_Details_Quantity] DEFAULT (1) FOR [Quantity];


GO
PRINT N'Creating [dbo].[DF_Order_Details_Discount]...';


GO
ALTER TABLE [dbo].[Order Details]
    ADD CONSTRAINT [DF_Order_Details_Discount] DEFAULT (0) FOR [Discount];


GO
PRINT N'Creating [dbo].[DF_Orders_Freight]...';


GO
ALTER TABLE [dbo].[Orders]
    ADD CONSTRAINT [DF_Orders_Freight] DEFAULT (0) FOR [Freight];


GO
PRINT N'Creating [dbo].[DF_Products_UnitPrice]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_UnitPrice] DEFAULT (0) FOR [UnitPrice];


GO
PRINT N'Creating [dbo].[DF_Products_UnitsInStock]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_UnitsInStock] DEFAULT (0) FOR [UnitsInStock];


GO
PRINT N'Creating [dbo].[DF_Products_UnitsOnOrder]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_UnitsOnOrder] DEFAULT (0) FOR [UnitsOnOrder];


GO
PRINT N'Creating [dbo].[DF_Products_ReorderLevel]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_ReorderLevel] DEFAULT (0) FOR [ReorderLevel];


GO
PRINT N'Creating [dbo].[DF_Products_Discontinued]...';


GO
ALTER TABLE [dbo].[Products]
    ADD CONSTRAINT [DF_Products_Discontinued] DEFAULT (0) FOR [Discontinued];


GO
PRINT N'Creating [dbo].[FK_CustomerCustomerDemo]...';


GO
ALTER TABLE [dbo].[CustomerCustomerDemo] WITH NOCHECK
    ADD CONSTRAINT [FK_CustomerCustomerDemo] FOREIGN KEY ([CustomerTypeID]) REFERENCES [dbo].[CustomerDemographics] ([CustomerTypeID]);


GO
PRINT N'Creating [dbo].[FK_CustomerCustomerDemo_Customers]...';


GO
ALTER TABLE [dbo].[CustomerCustomerDemo] WITH NOCHECK
    ADD CONSTRAINT [FK_CustomerCustomerDemo_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customers] ([CustomerID]);


GO
PRINT N'Creating [dbo].[FK_Employees_Employees]...';


GO
ALTER TABLE [dbo].[Employees] WITH NOCHECK
    ADD CONSTRAINT [FK_Employees_Employees] FOREIGN KEY ([ReportsTo]) REFERENCES [dbo].[Employees] ([EmployeeID]);


GO
PRINT N'Creating [dbo].[FK_EmployeeTerritories_Employees]...';


GO
ALTER TABLE [dbo].[EmployeeTerritories] WITH NOCHECK
    ADD CONSTRAINT [FK_EmployeeTerritories_Employees] FOREIGN KEY ([EmployeeID]) REFERENCES [dbo].[Employees] ([EmployeeID]);


GO
PRINT N'Creating [dbo].[FK_EmployeeTerritories_Territories]...';


GO
ALTER TABLE [dbo].[EmployeeTerritories] WITH NOCHECK
    ADD CONSTRAINT [FK_EmployeeTerritories_Territories] FOREIGN KEY ([TerritoryID]) REFERENCES [dbo].[Territories] ([TerritoryID]);


GO
PRINT N'Creating [dbo].[FK_Order_Details_Orders]...';


GO
ALTER TABLE [dbo].[Order Details] WITH NOCHECK
    ADD CONSTRAINT [FK_Order_Details_Orders] FOREIGN KEY ([OrderID]) REFERENCES [dbo].[Orders] ([OrderID]);


GO
PRINT N'Creating [dbo].[FK_Order_Details_Products]...';


GO
ALTER TABLE [dbo].[Order Details] WITH NOCHECK
    ADD CONSTRAINT [FK_Order_Details_Products] FOREIGN KEY ([ProductID]) REFERENCES [dbo].[Products] ([ProductID]);


GO
PRINT N'Creating [dbo].[FK_Orders_Customers]...';


GO
ALTER TABLE [dbo].[Orders] WITH NOCHECK
    ADD CONSTRAINT [FK_Orders_Customers] FOREIGN KEY ([CustomerID]) REFERENCES [dbo].[Customers] ([CustomerID]);


GO
PRINT N'Creating [dbo].[FK_Orders_Employees]...';


GO
ALTER TABLE [dbo].[Orders] WITH NOCHECK
    ADD CONSTRAINT [FK_Orders_Employees] FOREIGN KEY ([EmployeeID]) REFERENCES [dbo].[Employees] ([EmployeeID]);


GO
PRINT N'Creating [dbo].[FK_Orders_Shippers]...';


GO
ALTER TABLE [dbo].[Orders] WITH NOCHECK
    ADD CONSTRAINT [FK_Orders_Shippers] FOREIGN KEY ([ShipVia]) REFERENCES [dbo].[Shippers] ([ShipperID]);


GO
PRINT N'Creating [dbo].[FK_Products_Categories]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [FK_Products_Categories] FOREIGN KEY ([CategoryID]) REFERENCES [dbo].[Categories] ([CategoryID]);


GO
PRINT N'Creating [dbo].[FK_Products_Suppliers]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [FK_Products_Suppliers] FOREIGN KEY ([SupplierID]) REFERENCES [dbo].[Suppliers] ([SupplierID]);


GO
PRINT N'Creating [dbo].[FK_Territories_Region]...';


GO
ALTER TABLE [dbo].[Territories] WITH NOCHECK
    ADD CONSTRAINT [FK_Territories_Region] FOREIGN KEY ([RegionID]) REFERENCES [dbo].[Region] ([RegionID]);


GO
PRINT N'Creating [dbo].[CK_Birthdate]...';


GO
ALTER TABLE [dbo].[Employees] WITH NOCHECK
    ADD CONSTRAINT [CK_Birthdate] CHECK ([BirthDate] < getdate());


GO
PRINT N'Creating [dbo].[CK_Discount]...';


GO
ALTER TABLE [dbo].[Order Details] WITH NOCHECK
    ADD CONSTRAINT [CK_Discount] CHECK ([Discount] >= 0 and [Discount] <= 1);


GO
PRINT N'Creating [dbo].[CK_Quantity]...';


GO
ALTER TABLE [dbo].[Order Details] WITH NOCHECK
    ADD CONSTRAINT [CK_Quantity] CHECK ([Quantity] > 0);


GO
PRINT N'Creating [dbo].[CK_UnitPrice]...';


GO
ALTER TABLE [dbo].[Order Details] WITH NOCHECK
    ADD CONSTRAINT [CK_UnitPrice] CHECK ([UnitPrice] >= 0);


GO
PRINT N'Creating [dbo].[CK_Products_UnitPrice]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [CK_Products_UnitPrice] CHECK ([UnitPrice] >= 0);


GO
PRINT N'Creating [dbo].[CK_ReorderLevel]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [CK_ReorderLevel] CHECK ([ReorderLevel] >= 0);


GO
PRINT N'Creating [dbo].[CK_UnitsInStock]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [CK_UnitsInStock] CHECK ([UnitsInStock] >= 0);


GO
PRINT N'Creating [dbo].[CK_UnitsOnOrder]...';


GO
ALTER TABLE [dbo].[Products] WITH NOCHECK
    ADD CONSTRAINT [CK_UnitsOnOrder] CHECK ([UnitsOnOrder] >= 0);


GO
PRINT N'Checking existing data against newly created constraints';

GO

ALTER TABLE [dbo].[CustomerCustomerDemo] WITH CHECK CHECK CONSTRAINT [FK_CustomerCustomerDemo];

ALTER TABLE [dbo].[CustomerCustomerDemo] WITH CHECK CHECK CONSTRAINT [FK_CustomerCustomerDemo_Customers];

ALTER TABLE [dbo].[Employees] WITH CHECK CHECK CONSTRAINT [FK_Employees_Employees];

ALTER TABLE [dbo].[EmployeeTerritories] WITH CHECK CHECK CONSTRAINT [FK_EmployeeTerritories_Employees];

ALTER TABLE [dbo].[EmployeeTerritories] WITH CHECK CHECK CONSTRAINT [FK_EmployeeTerritories_Territories];

ALTER TABLE [dbo].[Order Details] WITH CHECK CHECK CONSTRAINT [FK_Order_Details_Orders];

ALTER TABLE [dbo].[Order Details] WITH CHECK CHECK CONSTRAINT [FK_Order_Details_Products];

ALTER TABLE [dbo].[Orders] WITH CHECK CHECK CONSTRAINT [FK_Orders_Customers];

ALTER TABLE [dbo].[Orders] WITH CHECK CHECK CONSTRAINT [FK_Orders_Employees];

ALTER TABLE [dbo].[Orders] WITH CHECK CHECK CONSTRAINT [FK_Orders_Shippers];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [FK_Products_Categories];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [FK_Products_Suppliers];

ALTER TABLE [dbo].[Territories] WITH CHECK CHECK CONSTRAINT [FK_Territories_Region];

ALTER TABLE [dbo].[Employees] WITH CHECK CHECK CONSTRAINT [CK_Birthdate];

ALTER TABLE [dbo].[Order Details] WITH CHECK CHECK CONSTRAINT [CK_Discount];

ALTER TABLE [dbo].[Order Details] WITH CHECK CHECK CONSTRAINT [CK_Quantity];

ALTER TABLE [dbo].[Order Details] WITH CHECK CHECK CONSTRAINT [CK_UnitPrice];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [CK_Products_UnitPrice];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [CK_ReorderLevel];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [CK_UnitsInStock];

ALTER TABLE [dbo].[Products] WITH CHECK CHECK CONSTRAINT [CK_UnitsOnOrder];


GO
PRINT N'Update complete.';


GO

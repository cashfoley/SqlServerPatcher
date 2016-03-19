
IF ('#{BlockDataLoss}' = 'True')
BEGIN
    /*
    Table [dbo].[Categories] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Categories])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Contacts] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Contacts])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[CustomerCustomerDemo] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[CustomerCustomerDemo])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[CustomerDemographics] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[CustomerDemographics])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Customers] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Customers])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Employees] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Employees])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[EmployeeTerritories] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[EmployeeTerritories])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Order Details] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Order Details])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Orders] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Orders])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Products] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Products])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Region] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Region])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Shippers] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Shippers])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Suppliers] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Suppliers])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    /*
    Table [dbo].[Territories] is being dropped.  Deployment will halt if the table contains data.
    */

    IF EXISTS (select top 1 1 from [dbo].[Territories])
        RAISERROR (N'Rows were detected. The schema update is terminating because data loss might occur.', 16, 127) WITH NOWAIT

    PRINT N'Dropping [dbo].[DF_Order_Details_UnitPrice]...';

END

GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_UnitPrice];


GO
PRINT N'Dropping [dbo].[DF_Order_Details_Quantity]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_Quantity];


GO
PRINT N'Dropping [dbo].[DF_Order_Details_Discount]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [DF_Order_Details_Discount];


GO
PRINT N'Dropping [dbo].[DF_Orders_Freight]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [DF_Orders_Freight];


GO
PRINT N'Dropping [dbo].[DF_Products_UnitPrice]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitPrice];


GO
PRINT N'Dropping [dbo].[DF_Products_UnitsInStock]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitsInStock];


GO
PRINT N'Dropping [dbo].[DF_Products_UnitsOnOrder]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_UnitsOnOrder];


GO
PRINT N'Dropping [dbo].[DF_Products_ReorderLevel]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_ReorderLevel];


GO
PRINT N'Dropping [dbo].[DF_Products_Discontinued]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [DF_Products_Discontinued];


GO
PRINT N'Dropping [dbo].[FK_Products_Categories]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [FK_Products_Categories];


GO
PRINT N'Dropping [dbo].[FK_CustomerCustomerDemo]...';


GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [FK_CustomerCustomerDemo];


GO
PRINT N'Dropping [dbo].[FK_CustomerCustomerDemo_Customers]...';


GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [FK_CustomerCustomerDemo_Customers];


GO
PRINT N'Dropping [dbo].[FK_Orders_Customers]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Customers];


GO
PRINT N'Dropping [dbo].[FK_Employees_Employees]...';


GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [FK_Employees_Employees];


GO
PRINT N'Dropping [dbo].[FK_EmployeeTerritories_Employees]...';


GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Employees];


GO
PRINT N'Dropping [dbo].[FK_Orders_Employees]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Employees];


GO
PRINT N'Dropping [dbo].[FK_Order_Details_Orders]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [FK_Order_Details_Orders];


GO
PRINT N'Dropping [dbo].[FK_Order_Details_Products]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [FK_Order_Details_Products];


GO
PRINT N'Dropping [dbo].[FK_Territories_Region]...';


GO
ALTER TABLE [dbo].[Territories] DROP CONSTRAINT [FK_Territories_Region];


GO
PRINT N'Dropping [dbo].[FK_Orders_Shippers]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Shippers];


GO
PRINT N'Dropping [dbo].[FK_Products_Suppliers]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [FK_Products_Suppliers];


GO
PRINT N'Dropping [dbo].[FK_EmployeeTerritories_Territories]...';


GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Territories];


GO
PRINT N'Dropping [dbo].[CK_Birthdate]...';


GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [CK_Birthdate];


GO
PRINT N'Dropping [dbo].[CK_Discount]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_Discount];


GO
PRINT N'Dropping [dbo].[CK_Quantity]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_Quantity];


GO
PRINT N'Dropping [dbo].[CK_UnitPrice]...';


GO
ALTER TABLE [dbo].[Order Details] DROP CONSTRAINT [CK_UnitPrice];


GO
PRINT N'Dropping [dbo].[CK_Products_UnitPrice]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_Products_UnitPrice];


GO
PRINT N'Dropping [dbo].[CK_ReorderLevel]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_ReorderLevel];


GO
PRINT N'Dropping [dbo].[CK_UnitsInStock]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_UnitsInStock];


GO
PRINT N'Dropping [dbo].[CK_UnitsOnOrder]...';


GO
ALTER TABLE [dbo].[Products] DROP CONSTRAINT [CK_UnitsOnOrder];


GO
PRINT N'Dropping [dbo].[Categories]...';


GO
DROP TABLE [dbo].[Categories];


GO
PRINT N'Dropping [dbo].[Contacts]...';


GO
DROP TABLE [dbo].[Contacts];


GO
PRINT N'Dropping [dbo].[CustomerCustomerDemo]...';


GO
DROP TABLE [dbo].[CustomerCustomerDemo];


GO
PRINT N'Dropping [dbo].[CustomerDemographics]...';


GO
DROP TABLE [dbo].[CustomerDemographics];


GO
PRINT N'Dropping [dbo].[Customers]...';


GO
DROP TABLE [dbo].[Customers];


GO
PRINT N'Dropping [dbo].[Employees]...';


GO
DROP TABLE [dbo].[Employees];


GO
PRINT N'Dropping [dbo].[EmployeeTerritories]...';


GO
DROP TABLE [dbo].[EmployeeTerritories];


GO
PRINT N'Dropping [dbo].[Order Details]...';


GO
DROP TABLE [dbo].[Order Details];


GO
PRINT N'Dropping [dbo].[Orders]...';


GO
DROP TABLE [dbo].[Orders];


GO
PRINT N'Dropping [dbo].[Products]...';


GO
DROP TABLE [dbo].[Products];


GO
PRINT N'Dropping [dbo].[Region]...';


GO
DROP TABLE [dbo].[Region];


GO
PRINT N'Dropping [dbo].[Shippers]...';


GO
DROP TABLE [dbo].[Shippers];


GO
PRINT N'Dropping [dbo].[Suppliers]...';


GO
DROP TABLE [dbo].[Suppliers];


GO
PRINT N'Dropping [dbo].[Territories]...';


GO
DROP TABLE [dbo].[Territories];


GO
PRINT N'Update complete.';


GO

PRINT N'Dropping [dbo].[DF_Order_Details_UnitPrice]...';


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
PRINT N'Dropping [dbo].[FK_Orders_Customers]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Customers];


GO
PRINT N'Dropping [dbo].[FK_CustomerCustomerDemo_Customers]...';


GO
ALTER TABLE [dbo].[CustomerCustomerDemo] DROP CONSTRAINT [FK_CustomerCustomerDemo_Customers];


GO
PRINT N'Dropping [dbo].[FK_Orders_Employees]...';


GO
ALTER TABLE [dbo].[Orders] DROP CONSTRAINT [FK_Orders_Employees];


GO
PRINT N'Dropping [dbo].[FK_EmployeeTerritories_Employees]...';


GO
ALTER TABLE [dbo].[EmployeeTerritories] DROP CONSTRAINT [FK_EmployeeTerritories_Employees];


GO
PRINT N'Dropping [dbo].[FK_Employees_Employees]...';


GO
ALTER TABLE [dbo].[Employees] DROP CONSTRAINT [FK_Employees_Employees];


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
PRINT N'Dropping [dbo].[EmployeeTerritories]...';


GO
DROP TABLE [dbo].[EmployeeTerritories];


GO
PRINT N'Dropping [dbo].[Region]...';


GO
DROP TABLE [dbo].[Region];


GO
PRINT N'Dropping [dbo].[Territories]...';


GO
DROP TABLE [dbo].[Territories];


GO
PRINT N'Dropping [dbo].[MinUnitPriceByCategory]...';


GO
DROP FUNCTION [dbo].[MinUnitPriceByCategory];


GO
PRINT N'Dropping [dbo].[TotalProductUnitPriceByCategory]...';


GO
DROP FUNCTION [dbo].[TotalProductUnitPriceByCategory];


GO
PRINT N'Dropping [dbo].[ProductsUnderThisUnitPrice]...';


GO
DROP FUNCTION [dbo].[ProductsUnderThisUnitPrice];


GO
PRINT N'Dropping [dbo].[Alphabetical list of products]...';


GO
DROP VIEW [dbo].[Alphabetical list of products];


GO
PRINT N'Dropping [dbo].[Category Sales for 1997]...';


GO
DROP VIEW [dbo].[Category Sales for 1997];


GO
PRINT N'Dropping [dbo].[Current Product List]...';


GO
DROP VIEW [dbo].[Current Product List];


GO
PRINT N'Dropping [dbo].[Customer and Suppliers by City]...';


GO
DROP VIEW [dbo].[Customer and Suppliers by City];


GO
PRINT N'Dropping [dbo].[Invoices]...';


GO
DROP VIEW [dbo].[Invoices];


GO
PRINT N'Dropping [dbo].[Sales by Category]...';


GO
DROP VIEW [dbo].[Sales by Category];


GO
PRINT N'Dropping [dbo].[Sales Totals by Amount]...';


GO
DROP VIEW [dbo].[Sales Totals by Amount];


GO
PRINT N'Dropping [dbo].[Summary of Sales by Quarter]...';


GO
DROP VIEW [dbo].[Summary of Sales by Quarter];


GO
PRINT N'Dropping [dbo].[Summary of Sales by Year]...';


GO
DROP VIEW [dbo].[Summary of Sales by Year];


GO
PRINT N'Dropping [dbo].[Orders Qry]...';


GO
DROP VIEW [dbo].[Orders Qry];


GO
PRINT N'Dropping [dbo].[Product Sales for 1997]...';


GO
DROP VIEW [dbo].[Product Sales for 1997];


GO
PRINT N'Dropping [dbo].[Products Above Average Price]...';


GO
DROP VIEW [dbo].[Products Above Average Price];


GO
PRINT N'Dropping [dbo].[Products by Category]...';


GO
DROP VIEW [dbo].[Products by Category];


GO
PRINT N'Dropping [dbo].[Quarterly Orders]...';


GO
DROP VIEW [dbo].[Quarterly Orders];


GO
PRINT N'Dropping [dbo].[Shippers]...';


GO
DROP TABLE [dbo].[Shippers];


GO
PRINT N'Dropping [dbo].[Suppliers]...';


GO
DROP TABLE [dbo].[Suppliers];


GO
PRINT N'Dropping [dbo].[Order Details Extended]...';


GO
DROP VIEW [dbo].[Order Details Extended];


GO
PRINT N'Dropping [dbo].[Customers By City]...';


GO
DROP PROCEDURE [dbo].[Customers By City];


GO
PRINT N'Dropping [dbo].[Customers Count By Region]...';


GO
DROP PROCEDURE [dbo].[Customers Count By Region];


GO
PRINT N'Dropping [dbo].[CustOrderHist]...';


GO
DROP PROCEDURE [dbo].[CustOrderHist];


GO
PRINT N'Dropping [dbo].[CustOrdersDetail]...';


GO
DROP PROCEDURE [dbo].[CustOrdersDetail];


GO
PRINT N'Dropping [dbo].[CustOrdersOrders]...';


GO
DROP PROCEDURE [dbo].[CustOrdersOrders];


GO
PRINT N'Dropping [dbo].[CustOrderTotal]...';


GO
DROP PROCEDURE [dbo].[CustOrderTotal];


GO
PRINT N'Dropping [dbo].[Employee Sales by Country]...';


GO
DROP PROCEDURE [dbo].[Employee Sales by Country];


GO
PRINT N'Dropping [dbo].[Get Customer And Orders]...';


GO
DROP PROCEDURE [dbo].[Get Customer And Orders];


GO
PRINT N'Dropping [dbo].[Sales by Year]...';


GO
DROP PROCEDURE [dbo].[Sales by Year];


GO
PRINT N'Dropping [dbo].[SalesByCategory]...';


GO
DROP PROCEDURE [dbo].[SalesByCategory];


GO
PRINT N'Dropping [dbo].[Ten Most Expensive Products]...';


GO
DROP PROCEDURE [dbo].[Ten Most Expensive Products];


GO
PRINT N'Dropping [dbo].[Whole Or Partial Customers Set]...';


GO
DROP PROCEDURE [dbo].[Whole Or Partial Customers Set];


GO
PRINT N'Dropping [dbo].[Order Subtotals]...';


GO
DROP VIEW [dbo].[Order Subtotals];


GO
PRINT N'Dropping [dbo].[Categories]...';


GO
DROP TABLE [dbo].[Categories];


GO
PRINT N'Dropping [dbo].[Customers]...';


GO
DROP TABLE [dbo].[Customers];


GO
PRINT N'Dropping [dbo].[Employees]...';


GO
DROP TABLE [dbo].[Employees];


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
PRINT N'Update complete.';


GO

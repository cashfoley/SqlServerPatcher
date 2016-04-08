PRINT N'Creating [dbo].[MinUnitPriceByCategory]...';


GO

CREATE FUNCTION [dbo].[MinUnitPriceByCategory]
(@categoryID INT
)
RETURNS Money
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar Money

	-- Add the T-SQL statements to compute the return value here
	SELECT @ResultVar = MIN(p.UnitPrice) FROM Products as p WHERE p.CategoryID = @categoryID

	-- Return the result of the function
	RETURN @ResultVar

END
GO
PRINT N'Creating [dbo].[TotalProductUnitPriceByCategory]...';


GO



CREATE FUNCTION [dbo].[TotalProductUnitPriceByCategory]
(@categoryID int)
RETURNS Money
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ResultVar Money

	-- Add the T-SQL statements to compute the return value here
	SELECT @ResultVar = (Select SUM(UnitPrice) 
						from Products 
						where CategoryID = @categoryID) 

	-- Return the result of the function
	RETURN @ResultVar

END
GO
PRINT N'Creating [dbo].[ProductsUnderThisUnitPrice]...';


GO



CREATE FUNCTION [dbo].[ProductsUnderThisUnitPrice]
(@price Money
)
RETURNS TABLE
AS
RETURN
	SELECT *
	FROM Products as P
	Where p.UnitPrice < @price
GO
PRINT N'Update complete.';


GO

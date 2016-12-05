
PRINT N'Disable FKs to dbo.Categories'
PRINT N'Disable FK [FK_Products_Categories] on [dbo].[Products]'
ALTER TABLE [dbo].[Products] NOCHECK CONSTRAINT [FK_Products_Categories]
GO

DECLARE @XmlDocument nvarchar(max)
SET @XmlDocument = N'<ROOT>
<dbo.Categories CategoryID="1" CategoryName="Bob" Description="Soft drinks, coffees, teas, beers, and ales" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''1'''']/@Picture" />
<dbo.Categories CategoryID="2" CategoryName="Condiments" Description="Sweet and savory sauces, relishes, spreads, and seasonings" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''2'''']/@Picture" />
<dbo.Categories CategoryID="3" CategoryName="Confections" Description="Desserts, candies, and sweet breads" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''3'''']/@Picture" />
<dbo.Categories CategoryID="4" CategoryName="Dairy Products" Description="Cheeses" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''4'''']/@Picture" />
<dbo.Categories CategoryID="5" CategoryName="Grains/Cereals" Description="Breads, crackers, pasta, and cereal" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''5'''']/@Picture" />
<dbo.Categories CategoryID="6" CategoryName="Meat/Poultry" Description="Prepared meats" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''6'''']/@Picture" />
<dbo.Categories CategoryID="8" CategoryName="Seafood" Description="Seaweed and fish" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''8'''']/@Picture" />
<dbo.Categories CategoryID="9" CategoryName="Dead People" Description="Seaweed and fish" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''8'''']/@Picture" />
<dbo.Categories CategoryID="10" CategoryName="More Dead People" Description="Seaweed and fish" Picture="dbobject/northwind.dbo.Categories[@CategoryID=''''8'''']/@Picture" />
</ROOT>'

DECLARE @DocHandle  int
EXEC sp_xml_preparedocument @DocHandle OUTPUT, @XmlDocument
SET IDENTITY_INSERT [dbo].[Categories] ON

DECLARE @ActionVar TABLE  
(  
    action VARCHAR(32) 
);  

BEGIN TRAN;
MERGE [dbo].[Categories] AS T
USING OPENXML (@DocHandle, '/ROOT/dbo.Categories',1) 
        WITH ( [CategoryID] int
             , [CategoryName] nvarchar(15)
             , [Description] ntext
             , [Picture] image
             ) AS S
   ON (T.[CategoryID] = S.[CategoryID]) 

 WHEN NOT MATCHED BY TARGET  
 THEN INSERT ( [CategoryID]
             , [CategoryName]
             , [Description]
             , [Picture]
             ) 
      VALUES ( S.[CategoryID]
             , S.[CategoryName]
             , S.[Description]
             , S.[Picture]
             )

 WHEN MATCHED AND (T.[CategoryName] <> S.[CategoryName])
 THEN UPDATE 
      SET T.[CategoryName] = S.[CategoryName]
        , T.[Description] = S.[Description]
        , T.[Picture] = S.[Picture]
 WHEN NOT MATCHED BY SOURCE 
 THEN DELETE 

OUTPUT $action INTO @ActionVar
;

DECLARE @DeleteCnt int
DECLARE @InsertCnt int
DECLARE @UpdateCnt int

DECLARE @ActionCount TABLE  
(  
    action VARCHAR(32), cnt int
);  


SELECT @DeleteCnt = count(*) FROM @ActionVar WHERE action = 'DELETE'
SELECT @InsertCnt = count(*) FROM @ActionVar WHERE action = 'INSERT'
SELECT @UpdateCnt = count(*) FROM @ActionVar WHERE action = 'UPDATE'

PRINT N'(Delete ' + CAST(@DeleteCnt as VARCHAR) + N' row(s) affected)'
PRINT N'(Insert ' + CAST(@InsertCnt as VARCHAR) + N' row(s) affected)'
PRINT N'(Update ' + CAST(@UpdateCnt as VARCHAR) + N' row(s) affected)'

SELECT * FROM [dbo].[Categories]

ROLLBACK TRAN;

SELECT * FROM [dbo].[Categories]

EXEC sp_xml_removedocument @DocHandle

SET IDENTITY_INSERT [dbo].[Categories] OFF



--*************************************************************************--
-- Title: Assignment06
-- Author: ABigley
-- Desc: This file demonstrates how to use Views
-- Change Log: When,Who,What
-- 2017-01-01,ABigley,Created File
--**************************************************************************--
Begin Try
	Use Master;
	If Exists(Select Name From SysDatabases Where Name = 'Assignment06DB_ABigley')
	 Begin 
	  Alter Database [Assignment06DB_ABigley] set Single_user With Rollback Immediate;
	  Drop Database Assignment06DB_ABigley;
	 End
	Create Database Assignment06DB_ABigley;
End Try
Begin Catch
	Print Error_Number();
End Catch
go
Use Assignment06DB_ABigley;

-- Create Tables (Module 01)-- 
Create Table Categories
([CategoryID] [int] IDENTITY(1,1) NOT NULL 
,[CategoryName] [nvarchar](100) NOT NULL
);
go

Create Table Products
([ProductID] [int] IDENTITY(1,1) NOT NULL 
,[ProductName] [nvarchar](100) NOT NULL 
,[CategoryID] [int] NULL  
,[UnitPrice] [mOney] NOT NULL
);
go

Create Table Employees -- New Table
([EmployeeID] [int] IDENTITY(1,1) NOT NULL 
,[EmployeeFirstName] [nvarchar](100) NOT NULL
,[EmployeeLastName] [nvarchar](100) NOT NULL 
,[ManagerID] [int] NULL  
);
go

Create Table Inventories
([InventoryID] [int] IDENTITY(1,1) NOT NULL
,[InventoryDate] [Date] NOT NULL
,[EmployeeID] [int] NOT NULL -- New Column
,[ProductID] [int] NOT NULL
,[Count] [int] NOT NULL
);
go

-- Add Constraints (Module 02) -- 
Begin  -- Categories
	Alter Table Categories 
	 Add Constraint pkCategories 
	  Primary Key (CategoryId);

	Alter Table Categories 
	 Add Constraint ukCategories 
	  Unique (CategoryName);
End
go 

Begin -- Products
	Alter Table Products 
	 Add Constraint pkProducts 
	  Primary Key (ProductId);

	Alter Table Products 
	 Add Constraint ukProducts 
	  Unique (ProductName);

	Alter Table Products 
	 Add Constraint fkProductsToCategories 
	  Foreign Key (CategoryId) References Categories(CategoryId);

	Alter Table Products 
	 Add Constraint ckProductUnitPriceZeroOrHigher 
	  Check (UnitPrice >= 0);
End
go

Begin -- Employees
	Alter Table Employees
	 Add Constraint pkEmployees 
	  Primary Key (EmployeeId);

	Alter Table Employees 
	 Add Constraint fkEmployeesToEmployeesManager 
	  Foreign Key (ManagerId) References Employees(EmployeeId);
End
go

Begin -- Inventories
	Alter Table Inventories 
	 Add Constraint pkInventories 
	  Primary Key (InventoryId);

	Alter Table Inventories
	 Add Constraint dfInventoryDate
	  Default GetDate() For InventoryDate;

	Alter Table Inventories
	 Add Constraint fkInventoriesToProducts
	  Foreign Key (ProductId) References Products(ProductId);

	Alter Table Inventories 
	 Add Constraint ckInventoryCountZeroOrHigher 
	  Check ([Count] >= 0);

	Alter Table Inventories
	 Add Constraint fkInventoriesToEmployees
	  Foreign Key (EmployeeId) References Employees(EmployeeId);
End 
go

-- Adding Data (Module 04) -- 
Insert Into Categories 
(CategoryName)
Select CategoryName 
 From Northwind.dbo.Categories
 Order By CategoryID;
go

Insert Into Products
(ProductName, CategoryID, UnitPrice)
Select ProductName,CategoryID, UnitPrice 
 From Northwind.dbo.Products
  Order By ProductID;
go

Insert Into Employees
(EmployeeFirstName, EmployeeLastName, ManagerID)
Select E.FirstName, E.LastName, IsNull(E.ReportsTo, E.EmployeeID) 
 From Northwind.dbo.Employees as E
  Order By E.EmployeeID;
go

Insert Into Inventories
(InventoryDate, EmployeeID, ProductID, [Count])
Select '20170101' as InventoryDate, 5 as EmployeeID, ProductID, UnitsInStock
From Northwind.dbo.Products
UNIOn
Select '20170201' as InventoryDate, 7 as EmployeeID, ProductID, UnitsInStock + 10 -- Using this is to create a made up value
From Northwind.dbo.Products
UNIOn
Select '20170301' as InventoryDate, 9 as EmployeeID, ProductID, UnitsInStock + 20 -- Using this is to create a made up value
From Northwind.dbo.Products
Order By 1, 2
go

-- Show the Current data in the Categories, Products, and Inventories Tables
Select * From Categories;
go
Select * From Products;
go
Select * From Employees;
go
Select * From Inventories;
go

/********************************* Questions and Answers *********************************/
print 
'NOTES------------------------------------------------------------------------------------ 
 1) You can use any name you like for you views, but be descriptive and consistent
 2) You can use your working code from assignment 5 for much of this assignment
 3) You must use the BASIC views for each table after they are created in Question 1
------------------------------------------------------------------------------------------'

-- Question 1 (5% pts): How can you create BASIC views to show data from each table in the database.
-- NOTES: 1) Do not use a *, list out each column!
--        2) Create one view per table!
--		  3) Use SchemaBinding to protect the views from being orphaned!
--
-- Create the view for Categories
GO
CREATE VIEW dbo.vCategories
WITH SCHEMABINDING
AS
SELECT
    c.CategoryID,
    c.CategoryName
FROM dbo.Categories AS c;
GO

-- Create the view for Products
CREATE VIEW dbo.vProducts
WITH SCHEMABINDING
AS
SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    p.UnitPrice
FROM dbo.Products AS p;
GO

-- Create the view for Employees
CREATE VIEW dbo.vEmployees
WITH SCHEMABINDING
AS
SELECT
    e.EmployeeID,
    e.EmployeeFirstName,
    e.EmployeeLastName,
    e.ManagerID
FROM dbo.Employees AS e;
GO

-- Create the view for Inventories
CREATE VIEW dbo.vInventories
WITH SCHEMABINDING
AS
SELECT
    i.InventoryID,
    i.InventoryDate,
    i.EmployeeID,
    i.ProductID,
    i.[Count]
FROM dbo.Inventories AS i;
GO

-- View the tables
SELECT * FROM dbo.vCategories;
SELECT * FROM dbo.vProducts;
SELECT * FROM dbo.vEmployees;
SELECT * FROM dbo.vInventories;

-- Question 2 (5% pts): How can you set permissions, so that the public group CANNOT select data 
-- from each table, but can select data from each view?
REVOKE SELECT ON dbo.Categories  FROM PUBLIC;
REVOKE SELECT ON dbo.Products    FROM PUBLIC;
REVOKE SELECT ON dbo.Employees   FROM PUBLIC;
REVOKE SELECT ON dbo.Inventories FROM PUBLIC;
GO

-- Question 3 (10% pts): How can you create a view to show a list of Category and Product names, 
-- and the price of each product?
-- Order the result by the Category and Product!
/* Andy's note--Part 1: First create the view.  A view can't be sorted when created, so I need a Part 2 step*/
CREATE VIEW dbo.vProductsByCategories
WITH SCHEMABINDING
AS
SELECT
    c.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    p.UnitPrice
FROM dbo.Categories AS c
JOIN dbo.Products   AS p
    ON c.CategoryID = p.CategoryID;
GO
/*Andy's note--Part 2: Now select the desired columns and order them*/
SELECT
    CategoryName,
    ProductName,
    UnitPrice
FROM dbo.vProductsByCategories
ORDER BY CategoryName, ProductName;
GO
-- Question 4 (10% pts): How can you create a view to show a list of Product names 
-- and Inventory Counts on each Inventory Date?
-- Order the results by the Product, Date, and Count!
/* Andy's note--Part 1: Similar to Q3; first create the view.  A view can't be sorted when created, so I need a Part 2 step*/
CREATE VIEW dbo.vInventoriesByProductsByDates
WITH SCHEMABINDING
AS
SELECT
    p.ProductID,
    p.ProductName,
    i.InventoryID,
    i.InventoryDate,
    i.[Count]
FROM dbo.Products    AS p
JOIN dbo.Inventories AS i
    ON p.ProductID = i.ProductID;
GO
/*Andy's note--Part 2: Now select the desired columns and order them*/
SELECT
    ProductName,
    InventoryDate,
    [Count]
FROM dbo.vInventoriesByProductsByDates
ORDER BY
    ProductName,
    InventoryDate,
    [Count];
GO
--SELECT * FROM vwInventoriesByProductsByDates;

-- Question 5 (10% pts): How can you create a view to show a list of Inventory Dates 
-- and the Employee that took the count?
-- Order the results by the Date and return only one row per date!
CREATE VIEW dbo.vInventoriesByEmployeesByDates
WITH SCHEMABINDING
AS
SELECT
    i.InventoryDate,
    MIN(i.EmployeeID) AS EmployeeID
FROM dbo.Inventories AS i
GROUP BY
    i.InventoryDate;
GO

SELECT 
    v.InventoryDate,
	e.EmployeeFirstName + ' ' + e.EmployeeLastName AS EmployeeName
FROM dbo.vInventoriesByEmployeesByDates AS v
JOIN dbo.Employees AS e
    ON v.EmployeeID = e.EmployeeID
ORDER BY v.InventoryDate;
GO
-- Here is are the rows selected from the view:
-- InventoryDate	EmployeeName
-- 2017-01-01	    Steven Buchanan
-- 2017-02-01	    Robert King
-- 2017-03-01	    Anne Dodsworth

-- Question 6 (10% pts): How can you create a view show a list of Categories, Products, 
-- and the Inventory Date and Count of each product?
-- Order the results by the Category, Product, Date, and Count!
CREATE VIEW dbo.vInventoriesByProductsByCategories
WITH SCHEMABINDING
AS
SELECT
    c.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    i.InventoryID,
    i.InventoryDate,
    i.[Count]
FROM dbo.Categories  AS c
JOIN dbo.Products    AS p
    ON c.CategoryID = p.CategoryID
JOIN dbo.Inventories AS i
    ON p.ProductID = i.ProductID;
GO

SELECT
    CategoryName,
    ProductName,
    InventoryDate,
    [Count]
FROM dbo.vInventoriesByProductsByCategories
ORDER BY
    CategoryName,
    ProductName,
    InventoryDate,
    [Count]
GO

-- Question 7 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the EMPLOYEE who took the count?
-- Order the results by the Inventory Date, Category, Product and Employee!
CREATE VIEW dbo.vInventoriesByProductsByEmployees
WITH SCHEMABINDING
AS
SELECT
    c.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    i.InventoryID,
    i.InventoryDate,
    i.[Count],
    e.EmployeeID,
    e.EmployeeFirstName,
    e.EmployeeLastName
FROM dbo.Categories  AS c
JOIN dbo.Products    AS p
    ON c.CategoryID = p.CategoryID
JOIN dbo.Inventories AS i
    ON p.ProductID = i.ProductID
JOIN dbo.Employees   AS e
    ON e.EmployeeID = i.EmployeeID;
GO

SELECT
    CategoryName,
    ProductName,
    InventoryDate,
    [Count],
    EmployeeFirstName + ' ' + EmployeeLastName AS EmployeeName
FROM dbo.vInventoriesByProductsByEmployees
ORDER BY
    InventoryDate,
    CategoryName,
    ProductName,
    EmployeeName;
GO

-- Question 8 (10% pts): How can you create a view to show a list of Categories, Products, 
-- the Inventory Date and Count of each product, and the Employee who took the count
-- for the Products 'Chai' and 'Chang'? 
CREATE VIEW dbo.vInventoriesForChaiAndChangByEmployees
WITH SCHEMABINDING
AS
SELECT
    c.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    i.InventoryID,
    i.InventoryDate,
    i.[Count],
    e.EmployeeID,
    e.EmployeeFirstName,
    e.EmployeeLastName
FROM dbo.Categories  AS c
JOIN dbo.Products    AS p
    ON c.CategoryID = p.CategoryID
JOIN dbo.Inventories AS i
    ON p.ProductID = i.ProductID
JOIN dbo.Employees   AS e
    ON e.EmployeeID = i.EmployeeID
WHERE
    p.ProductName IN ('Chai', 'Chang');
GO

SELECT
    v.CategoryName,
    v.ProductName,
    v.InventoryDate,
    v.[Count],
    v.EmployeeFirstName + ' ' + v.EmployeeLastName AS EmployeeName
FROM dbo.vInventoriesForChaiAndChangByEmployees AS v
ORDER BY
    v.InventoryDate,
    v.CategoryName,
    v.ProductName,
    EmployeeName;
GO

-- Question 9 (10% pts): How can you create a view to show a list of Employees and the Manager who manages them?
-- Order the results by the Manager's name!
CREATE VIEW dbo.vEmployeesByManager
WITH SCHEMABINDING
AS
SELECT
    e.EmployeeID,
    e.EmployeeFirstName,
    e.EmployeeLastName,
    e.ManagerID,
    m.EmployeeFirstName AS ManagerFirstName,
    m.EmployeeLastName  AS ManagerLastName
FROM dbo.Employees AS e
JOIN dbo.Employees AS m
    ON e.ManagerID = m.EmployeeID;
GO

SELECT
    e.ManagerFirstName  + ' ' + e.ManagerLastName       AS Manager,
    e.EmployeeFirstName + ' ' + e.EmployeeLastName      AS Employee
FROM dbo.vEmployeesByManager AS e
ORDER BY
    Manager,
    Employee;
GO


-- Question 10 (20% pts): How can you create one view to show all the data from all four 
-- BASIC Views? Also show the Employee's Manager Name and order the data by 
-- Category, Product, InventoryID, and Employee.
CREATE VIEW dbo.vInventoriesByProductsByCategoriesByEmployees
AS
SELECT
    c.CategoryID,
    c.CategoryName,
    p.ProductID,
    p.ProductName,
    p.UnitPrice,
    i.InventoryID,
    i.InventoryDate,
    i.[Count],
    e.EmployeeID,
    e.EmployeeFirstName,
    e.EmployeeLastName,
    e.ManagerID,
    m.EmployeeFirstName AS ManagerFirstName,
    m.EmployeeLastName  AS ManagerLastName
FROM dbo.vCategories   AS c
JOIN dbo.vProducts     AS p
    ON c.CategoryID = p.CategoryID
JOIN dbo.vInventories  AS i
    ON p.ProductID = i.ProductID
JOIN dbo.vEmployees    AS e
    ON i.EmployeeID = e.EmployeeID
JOIN dbo.vEmployees    AS m
    ON e.ManagerID = m.EmployeeID;
GO

SELECT
    CategoryID,
    CategoryName,
    ProductID,
    ProductName,
    UnitPrice,
    InventoryID,
    InventoryDate,
    [Count],
    EmployeeID,
    e.EmployeeFirstName + ' ' + e.EmployeeLastName       AS Employee,
    e.ManagerFirstName  + ' ' + e.ManagerLastName        AS Manager
FROM dbo.vInventoriesByProductsByCategoriesByEmployees AS e
ORDER BY
    CategoryName,
    ProductName,
    InventoryID,
    Employee;
GO

--DROP VIEW dbo.vwAllCategoryProductInventoryEmployees
-- Test your Views (NOTE: You must change the your view names to match what I have below!)
Print 'Note: You will get an error until the views are created!'
Select * From [dbo].[vCategories]
Select * From [dbo].[vProducts]
Select * From [dbo].[vInventories]
Select * From [dbo].[vEmployees]

Select * From [dbo].[vProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByDates]
Select * From [dbo].[vInventoriesByEmployeesByDates]
Select * From [dbo].[vInventoriesByProductsByCategories]
Select * From [dbo].[vInventoriesByProductsByEmployees]
Select * From [dbo].[vInventoriesForChaiAndChangByEmployees]
Select * From [dbo].[vEmployeesByManager]
Select * From [dbo].[vInventoriesByProductsByCategoriesByEmployees]

/***************************************************************************************/
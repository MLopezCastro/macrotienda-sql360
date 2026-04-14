
SELECT ProductID 
FROM Production.ProductInventory 
WHERE Quantity > 1000;
--no hay--

---
SELECT *
FROM Sales.SalesOrderDetail;

SELECT 
	ProductID, 
	ROUND(OrderQty * (UnitPrice - UnitPrice * UnitPriceDiscount),2) AS TotalIngresos
FROM Sales.SalesOrderDetail
ORDER BY TotalIngresos DESC;

---
SELECT 
	SalesOrderID, 
	SUM(OrderQty) AS CantidadProductos, 
	SUM(LineTotal) AS TotalIngresos
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID

---
SELECT *
FROM HumanResources.Employee

----
SELECT COUNT(JobTitle) AS Cantidad, JobTitle
FROM HumanResources.Employee
GROUP BY JobTitle
ORDER BY count(JobTitle) DESC;
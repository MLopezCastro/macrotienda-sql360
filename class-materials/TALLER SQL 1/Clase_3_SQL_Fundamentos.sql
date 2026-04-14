USE Adventureworks2019; 

SELECT  DISTINCT
		-- BusinessEntityID,
		FirstName,
		LastName
FROM Person.Person
WHERE FirstName = 'Pilar' AND LastName = 'Ackerman'

SELECT DISTINCT Color
FROM Production.Product
WHERE Color IS NOT NULL

---------------------------------------- CLASE 3 -------------------------------------------------

SELECT	BusinessEntityID, 
		BirthDate,
		MONTH(BirthDate) AS Mes,
		YEAR(BirthDate) AS Anio,
		DATENAME(MONTH,BirthDate) AS Nombre_mes,
		DATEDIFF(YEAR,BirthDate,GETDATE()) AS Dif_anios
FROM HumanResources.Employee; 

SELECT	SalesOrderID, -- Var.Cualitativa
		COUNT(ProductID) AS Productos, -- Metrica 1
		SUM(OrderQty) AS Unidades, -- Metrica 2
		SUM(OrderQty * ROUND(UnitPrice,2)) AS MontoFinal -- Metrica 3
FROM Sales.SalesOrderDetail
-- WHERE SalesOrderID = 43659
GROUP BY SalesOrderID;



SELECT	TerritoryID, 
		-- SalesPersonID, 
		COUNT(SalesOrderID) AS Tickets,
		SUM(TotalDue) AS Ingresos
FROM Sales.SalesOrderHeader
-- WHERE TerritoryID = 10 AND SalesPersonID IS NOT NULL
GROUP BY TerritoryID-- , SalesPersonID
HAVING COUNT(SalesOrderID) >= 5000

--------------------------------------- CASE & END ----------------------------------------------

-- Segmentar Nomina de Clientes
-- Si el cliente realizo mas de 20 compras entonces es Premium
-- Si realizo entre 10 y 19 compras es Plata
-- Si realizo menos de 10 compras es Bronce.

SELECT	CustomerID, 
		COUNT(SalesOrderID) AS Tickets,
		CASE
			WHEN COUNT(SalesOrderID) >= 20 THEN 'Premium'
			WHEN COUNT(SalesOrderID) BETWEEN 10 AND 19 THEN 'Plata'
			ELSE 'Bronce'
		END AS Segmento
FROM Sales.SalesOrderHeader -- Tabla de Tickets
--- WHERE CustomerID = 29825
GROUP BY CustomerID
ORDER BY Tickets DESC





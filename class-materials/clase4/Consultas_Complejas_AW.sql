USE AdventureWorks2019; 

-- Subconsulta Correlacionado 
SELECT	T1.CustomerID,
		CONCAT(T2.FirstName,' ',T2.LastName) AS Nombre,
		(SELECT COUNT(SalesOrderID) FROM Sales.SalesOrderHeader AS T3 WHERE T1.CustomerID = T3.CustomerID) AS Cantidad_Ordenes
FROM Sales.Customer AS T1
LEFT JOIN Person.Person AS T2
	ON T1.CustomerID = T2.BusinessEntityID

-- Recaudacion Total de Canada
SELECT TerritoryID, TotalDue 
FROM Sales.SalesOrderHeader
WHERE TerritoryID = (SELECT TerritoryID FROM Sales.SalesTerritory WHERE [Name] = 'Canada'); 

-------------------------------------------------------------------------------------------

-- CTE: Common Table Expressions

-- Saber La cantidad de Ordenes emitidas y Recaudacion por cada segmento de clientes. 
-- Si el cliente tiene mas de 20 ordenes (PREMIUM)
-- Si el cliente tiene entre 5 y 19 ordenes (Standard)
-- Si el cliente tiene menos de 5 ordenes (Nuevo)


WITH Segmento_Customer AS
	(SELECT	CustomerID, 
			COUNT(SalesOrderID) AS CantidadOrdenes, 
			SUM(TotalDue) AS Ingresos,
			CASE
				WHEN COUNT(SalesOrderID) >= 20 THEN 'Premium'
				WHEN COUNT(SalesOrderID) BETWEEN 5 AND 19 THEN 'Standard'
				ELSE 'Nuevo'
			END AS Segmento 
	FROM Sales.SalesOrderHeader
	GROUP BY CustomerID)
SELECT	Segmento,
		COUNT(CustomerID) AS Cantidad_Clientes, -- Metrica 1
		SUM(CantidadOrdenes) AS Cantidad_Ordenes, -- Metrica 2
		SUM(Ingresos) AS Recaudacion -- Metrica
FROM Segmento_Customer 
GROUP BY Segmento

-------------------------------- FUNCIONES VENTANA --------------------------------------
-- Como se distribuye la recaudacion total del negocio sobre las 10 sucursales.

SELECT DISTINCT
		TerritoryID, -- Cualitativa
		--SUM(TotalDue) OVER(PARTITION BY TerritoryID) AS Recaudacion_Territorio, -- Metrica1
		--SUM(TotalDue) OVER() AS Recaudacion_Total, -- Metrica2
		(SUM(TotalDue) OVER(PARTITION BY TerritoryID) / SUM(TotalDue) OVER())* 100-- Metrica3
FROM Sales.SalesOrderHeader









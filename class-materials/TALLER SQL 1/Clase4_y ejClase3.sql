------CLASE 3--------------

SELECT *
FROM HumanResources.Employee;

---

SELECT *
FROM Production.ProductInventory;
--- Obtener un listado de Productos que tengan mas de 1000 articulos totales en Inventario.

SELECT ProductID, --variable cualitativa
	   SUM (Quantity) AS Cantidad --METRICA
FROM Production.ProductInventory
GROUP BY ProductID --variable cualitativa

------------

SELECT ProductID, --variable cualitativa
	   SUM (Quantity) AS Cantidad --METRICA
FROM Production.ProductInventory
GROUP BY ProductID --variable cualitativa
HAVING SUM (Quantity) > 1000; 
--HAVING VA DSPS DE GROUP BY

------------------

--- Obtener el total de ingreso por cada Producto Vendido. 

SELECT * FROM Sales.SalesOrderDetail;

--

SELECT  ProductID,-------cualitativa
		SUM ((OrderQty) * UnitPrice) AS TotalSales,
		SUM (OrderQty) AS CantidadUnidades,
		(SUM ((OrderQty) * UnitPrice)) / (SUM (OrderQty)) AS PrecioPromedio,
		UnitPrice---------cuantitativa
FROM Sales.SalesOrderDetail
GROUP BY ProductID, UnitPrice
ORDER BY TotalSales  DESC;

--------
SELECT  TOP 1
		ProductID,-------cualitativa
		SUM ((OrderQty) * UnitPrice) AS TotalSales,
		SUM (OrderQty) AS CantidadUnidades,
		(SUM ((OrderQty) * UnitPrice)) / (SUM (OrderQty)) AS PrecioPromedio,
		UnitPrice---------cualitativa
FROM Sales.SalesOrderDetail
GROUP BY ProductID, UnitPrice
ORDER BY TotalSales  DESC

---
SELECT  ProductID,-------cualitativa
		SUM ((OrderQty) * UnitPrice) AS TotalSales,
		SUM (OrderQty) AS CantidadUnidades,
		(SUM ((OrderQty) * UnitPrice)) / (SUM (OrderQty)) AS PrecioPromedio,
		UnitPrice---------cuantitativa
FROM Sales.SalesOrderDetail
GROUP BY ProductID, UnitPrice
ORDER BY ProductID  DESC;


-----
--3. De la tabla de Transacciones (OrderDetail)
--- Obtener la cantidad de Productos y Recaudacion por Orden/Ticket. 

SELECT * FROM Sales.SalesOrderDetail;

SELECT SalesOrderID, 
	   SUM(LineTotal) AS Ingresos, 
	   SUM(OrderQty) AS Cantidad_Productos
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID
ORDER BY SalesOrderID ASC;

----
--4. De la tabla de Nomina de Empleados Activos. 
--- Obtener la cantidad de empleados que tiene el Equipo de Marketing, 
--el Equipo de Production y Human Resources.

SELECT * FROM HumanResources.Employee;

SELECT COUNT(BusinessEntityID), JobTitle
FROM HumanResources.Employee
WHERE JobTitle LIKE '%Mark%' OR JobTitle LIKE '%Eng%'OR JobTitle LIKE '%Hum%'
GROUP BY JobTitle;


---
SELECT 
  COUNT(BusinessEntityID) AS CantEmpleados, 
  CASE 
    WHEN JobTitle LIKE '%Mark%' THEN 'Marketing'
    WHEN JobTitle LIKE '%Eng%' THEN 'Engineering'
    WHEN JobTitle LIKE '%Hum%' THEN 'Human Resources'
    ELSE 'Otros'
  END AS Departamento
FROM HumanResources.Employee
WHERE JobTitle LIKE '%Mark%' 
   OR JobTitle LIKE '%Eng%' 
   OR JobTitle LIKE '%Hum%'
GROUP BY 
  CASE 
    WHEN JobTitle LIKE '%Mark%' THEN 'Marketing'
    WHEN JobTitle LIKE '%Eng%' THEN 'Engineering'
    WHEN JobTitle LIKE '%Hum%' THEN 'Human Resources'
    ELSE 'Otros'
  END;


-------
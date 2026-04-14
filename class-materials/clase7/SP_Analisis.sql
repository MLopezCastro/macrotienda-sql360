

USE Macrotienda_bk; 

-- El siguiente SP genera dos consultas a partir de un parametro de entrado que hara mencion al segmento de los clientes.
-- En caso de ingresar premium se obtiene en una primera consulta la cantidad de ventas generadas y rentabilidad por ese segmento.
-- En una segunda consulta se obtiene el listado de clientes correspondientes a dicha consulta.
-- Existen dos segmentos, basico con ventas menores a 20 facturas y premium donde las ventas superan las 20 facturas generadas. 

GO
CREATE PROCEDURE Prod.sp_SegmentosClientes(@v_segmento VARCHAR(20))
AS -- Delimitar el encabezado del cuerpo del objeto que estamos creando. 
BEGIN
	WITH SegmentoCliente AS
		(SELECT	T3.Nombre,
				COUNT(DISTINCT(T1.[ID Factura])) AS Facturas,
				SUM(T1.[Precio Unitario] * T1.Cantidad) AS Facturacion,
				CASE
					WHEN COUNT(DISTINCT(T1.[ID Factura])) >= 20 THEN 'Premium'
					ELSE 'Standard'
				END AS Segmento 
		FROM Prod.Transacciones AS T1
		LEFT JOIN Prod.Invoice AS T2
			ON T1.[ID Factura] = T2.[ID Factura]
		LEFT JOIN Prod.Clientes AS T3
			ON T2.[ID Cliente] = T3.[ID Cliente]
		GROUP BY T3.Nombre)
	-- Invocamos el CTE
	SELECT	Segmento,
			COUNT(Nombre) AS CantidadClientes, 
			SUM(Facturas) AS CantidadFacturas,
			FORMAT(SUM(Facturacion),'C','es-MX') AS Facturacion
	FROM SegmentoCliente
	WHERE Segmento LIKE CONCAT('%',@v_segmento,'%')
	GROUP BY Segmento;

	-- SEGUNDA CONSULTA DEL SP
	WITH ListadoClientes AS
		(SELECT	T3.Nombre,
				COUNT(DISTINCT(T1.[ID Factura])) AS Facturas,
				SUM(T1.[Precio Unitario] * T1.Cantidad) AS Facturacion,
				CASE
					WHEN COUNT(DISTINCT(T1.[ID Factura])) >= 20 THEN 'Premium'
					ELSE 'Standard'
				END AS Segmento 
		FROM Prod.Transacciones AS T1
		LEFT JOIN Prod.Invoice AS T2
			ON T1.[ID Factura] = T2.[ID Factura]
		LEFT JOIN Prod.Clientes AS T3
			ON T2.[ID Cliente] = T3.[ID Cliente]
		GROUP BY T3.Nombre)
	SELECT Nombre FROM ListadoClientes WHERE Segmento LIKE CONCAT('%',@v_segmento,'%') 
END;
GO

-- Invocamos el SP
EXEC Prod.sp_SegmentosClientes'Premiu' -- MySQL: CALL 

------------------------------------ STORES PROCEDURE 2 ---------------------------------------------

GO
CREATE PROCEDURE Prod.sp_AumentoProveedor(@v_aumento DECIMAL(5,2),@v_marca VARCHAR(1))
AS -- Delimita el encabezado del cuerpo de SP.
BEGIN
IF @v_marca IN ('V','C','Z','N','E')
	SELECT	T2.[ID Producto],
			T3.Nombre,
			CONVERT(DECIMAL(18,2), AVG(T1.[Costo Unitario])) AS CostoActual,
			CONVERT(DECIMAL(18,2), AVG(T1.[Costo Unitario])) + CONVERT(DECIMAL(18,2), AVG(T1.[Costo Unitario]*@v_aumento)) AS CostoAumento
	FROM Prod.Transacciones AS T1
	LEFT JOIN Prod.Productos AS T2
		ON T1.[ID Producto] = T2.[ID Producto]
	LEFT JOIN Prod.Marcas AS T3
		ON T2.Marca = T3.[ID Marca]
	WHERE LEFT(T3.Nombre,1) = @v_marca
	GROUP BY T2.[ID Producto], T3.Nombre;
ELSE 
	PRINT('Proveedor Incorrecto')
END;
GO

EXEC Prod.sp_AumentoProveedor '0.20','v'

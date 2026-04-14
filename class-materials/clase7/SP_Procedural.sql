--El orden lógico dentro de tu SP de ventas sería:

--Validar: ¿Hay unidades suficientes en Prod.Producto?
--Insertar Padre: Crear la fila en Prod.Invoice.
--Obtener ID: Capturar el ID Factura recién generado (usando SCOPE_IDENTITY()).
--Insertar Detalle: Cargar las filas en Prod.Transacciones usando ese ID.
--Actualizar Stock: Restar las unidades en Prod.Producto.




-- Creacion de Base de Datos
CREATE DATABASE Prueba1; 
GO
-- Posicionamos nuestra BBDD
USE Prueba1;
GO

GO
CREATE SCHEMA Prod;
GO


CREATE TABLE Prod.Productos(
	[ID Producto] INT PRIMARY KEY, 
	[Producto] VARCHAR(255),
	[Stock] INT); 
GO

CREATE TABLE Prod.Invoice(
	[ID Factura] INT PRIMARY KEY IDENTITY,
	[Fecha de Venta] DATE); 
GO

CREATE TABLE Prod.Transacciones(
	[ID Transaccion] INT PRIMARY KEY IDENTITY,
	[ID Factura] INT,
	[ID Producto] INT, 
	[Cantidad] INT,
	[Precio Unitario] DECIMAL(18,2)); 
GO

-- Generamos las relaciones entre las tablas
ALTER TABLE Prod.Transacciones 
ADD CONSTRAINT FK_Transacciones_Producto
FOREIGN KEY ([ID Producto]) REFERENCES Prod.Productos([ID Producto]);
GO

ALTER TABLE Prod.Transacciones
ADD CONSTRAINT FK_Transacciones_Factura
FOREIGN KEY([ID Factura]) REFERENCES Prod.Invoice([ID Factura]); 
GO

INSERT INTO Prod.Productos VALUES(1,'Teclado',15),(2,'Auriculares',20),(3,'Sillas',40); 
GO 

------------------------------- CREACION DEL SP -------------------------------------------------

GO
CREATE PROCEDURE Prod.sp_RegistrarVenta(@IDProducto INT,@Cantidad INT,@PrecioUnitario DECIMAL(18,2))
AS -- Delimita el encabezado del cuerpo del SP.
BEGIN
	SET NOCOUNT ON;

	DECLARE @StockActual INT;
	DECLARE @NuevoIDFactura INT; 

	-- Iniciamos con la Transacccion/Sp.
	BEGIN TRANSACTION; 

	-- Intenta transaccionar el siguiente programa 
	BEGIN TRY
		-- Inicialmente validando Stock
		SET @StockActual = (SELECT Stock FROM Prod.Productos WHERE [ID Producto] = @IDProducto)

		IF @StockActual < @Cantidad -- TRUE/FALSE
		BEGIN	
			-- Si no hay stock lance un mensaje de error.
			RAISERROR('Stock Insuficiente para realizar la venta.',16,1);
			ROLLBACK TRANSACTION;
			RETURN;
		END

		-- Inserta un registro en la tabla de facturas
		INSERT INTO Prod.Invoice([Fecha de Venta]) VALUES (GETDATE());

		-- Copiar el ID Factura nuevo para impactar en la FK de Transacciones.
		SET @NuevoIDFactura = SCOPE_IDENTITY()

		-- Insertar un registro en la tabla de Transacciones.
		INSERT INTO Prod.Transacciones([ID Factura],[ID Producto],[Cantidad],[Precio Unitario])
			VALUES(@NuevoIDFactura,@IDProducto,@Cantidad,@PrecioUnitario)

		-- Ejecutar una modificacion sobre las unidades del producto vendido. 
		UPDATE Prod.Productos
			SET Stock = Stock - @Cantidad
			WHERE [ID Producto] = @IDProducto

		-- Si todo sale bien. 
		COMMIT TRANSACTION; 
		PRINT('Transaccion Realizada Correctamente');
	
	-- Cierra el programa en caso que todo salga bien.
	END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
		PRINT('Existieron otros errores dentro de la ejecucion.')
	END CATCH
END;
GO

EXEC Prod.sp_RegistrarVenta 3,5,250.00

SELECT * FROM Prod.Transacciones; 

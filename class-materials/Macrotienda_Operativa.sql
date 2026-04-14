USE Macrotienda_bk;


-- CREAMOS SCHEMA DE PRODUCCION
CREATE SCHEMA prod; 

-- CREAMOS LA TABLA DE CLIENTES
CREATE TABLE prod.Clientes(
[ID Cliente] INT PRIMARY KEY,
[Nombre] VARCHAR(255) NOT NULL,
[Pais Cliente] VARCHAR(255) NOT NULL); 

-- CREACION DE LA TABLA PROVEEDORES
CREATE TABLE prod.Marcas(
[ID Marca] INT PRIMARY KEY IDENTITY,
[Nombre] VARCHAR(255) NOT NULL,
[Centro Logistico] VARCHAR(255) NOT NULL,
[Latitud] DECIMAL(9,5) NOT NULL,
[Longitud] DECIMAL(9,5) NOT NULL); 

-- CREACION DE TABLA PRODUCTOS
CREATE TABLE prod.Productos(
[ID Producto] INT PRIMARY KEY,
[Producto] TEXT NOT NULL,
[Marca] INT); 

-- GENERAMOS UN CAMPO NUEVO
ALTER TABLE prod.Productos
ADD [Stock] INT;  

-- CREACION DE TABLA REGIONES/MERCADOS
CREATE TABLE prod.Mercados(
[ID Region] INT PRIMARY KEY IDENTITY,
[Nombre] VARCHAR(255) NOT NULL); 

-- CREACION DE TABLA VENDEDORES
CREATE TABLE prod.Vendedores(
[ID Vendedor] INT PRIMARY KEY,
[Vendedor] VARCHAR(255) NOT NULL,
[Fecha Nacimiento] DATE NOT NULL,
[Mercados] INT); 

-- CREACION DE TABLA DE FACTURAS
CREATE TABLE prod.Invoice(
[ID Factura] INT PRIMARY KEY,
[Fecha de Venta] DATE NOT NULL,
[ID Vendedor] INT,
[ID Cliente] INT,
[ID Region] INT); 

-- CREACION DE TABLA DE TRANSACCIONES
CREATE TABLE prod.Transacciones(
[ID Transaccion] INT PRIMARY KEY,
[Fecha de Recepcion] DATE NOT NULL,
[ID Factura] INT,
[ID Producto] INT,
[Cantidad] INT NOT NULL,
[Precio Unitario] DECIMAL(9,2) NOT NULL,
[Costo Unitario] DECIMAL(9,2) NOT NULL); 

------------------------------------------- CREAMOS LAS RELACIONES ----------------------------------------------------------

-- GENERAMOS LA RELACION ENTRE PRODUCTOS Y MARCAS
ALTER TABLE prod.Productos
ADD CONSTRAINT FK_Prod_Marcas
FOREIGN KEY([Marca]) REFERENCES prod.Marcas([ID Marca])
ON DELETE SET NULL ON UPDATE SET NULL; 

-- GENERAR RELACIONES ENTRE INVOICE Y VENDEDORES
ALTER TABLE prod.Invoice
ADD CONSTRAINT FK_Invoice_Vendedores
FOREIGN KEY ([ID Vendedor]) REFERENCES prod.Vendedores([ID Vendedor])
ON DELETE SET NULL ON UPDATE SET NULL; 

-- GENERAR RELACIONES ENTRE INVOICE Y CLIENTES
ALTER TABLE prod.Invoice
ADD CONSTRAINT FK_Invoice_Clientes
FOREIGN KEY([ID Cliente]) REFERENCES prod.Clientes([ID Cliente])
ON DELETE NO ACTION ON UPDATE NO ACTION; 

-- GENERAR RELACIONES ENTRE INVOICE Y MERCADOS
ALTER TABLE prod.Invoice
ADD CONSTRAINT FK_Invoice_Mercados
FOREIGN KEY([ID Region]) REFERENCES prod.Mercados([ID Region])
ON DELETE NO ACTION ON UPDATE NO ACTION; 

-- GENERAR RELACIONES ENTRE TRANSACCIONES Y PRODUCTOS
ALTER TABLE prod.Transacciones
ADD CONSTRAINT FK_Transacciones_Productos
FOREIGN KEY([ID Producto]) REFERENCES prod.Productos([ID Producto])
ON DELETE SET NULL ON UPDATE SET NULL; 

-- GENERAR RELACIONES ENTRE TRANSACCIONES Y FACTURAS
ALTER TABLE prod.Transacciones
ADD CONSTRAINT FK_Transacciones_Invoice
FOREIGN KEY([ID Factura]) REFERENCES prod.Invoice([ID Factura])
ON DELETE SET NULL ON UPDATE SET NULL; 

-- GENERAR RELACION ENTRE VENDEDORES Y MERCADOS
ALTER TABLE Prod.Vendedores
ADD CONSTRAINT FK_Vendedores_Mercados
FOREIGN KEY([Mercados]) REFERENCES Prod.Mercados([Id Region])

------------------------------------ ZONA DE ATERRIZAJE ------------------------------------------------

CREATE TABLE #VentasTemp(
[ID Transaccion] VARCHAR(255) NOT NULL,
[ID Factura] VARCHAR(255) NOT NULL,
[Fecha de Venta] VARCHAR(255) NOT NULL,
[Fecha de Recepcion] VARCHAR(255) NOT NULL,
[ID Producto] VARCHAR(255) NOT NULL,
[Producto] VARCHAR(255) NOT NULL,
[Marca] VARCHAR(255) NOT NULL,
[Centro Logistico] VARCHAR(255) NOT NULL,
[Latitud] VARCHAR(255) NOT NULL,
[Longitud] VARCHAR(255) NOT NULL,
[ID Vendedor] VARCHAR(255) NOT NULL,
[Nombre Vendedor] VARCHAR(255) NOT NULL,
[Apellido Vendedor] VARCHAR(255) NOT NULL,
[Fecha Nacimiento] VARCHAR(255) NOT NULL,
[Mercados] VARCHAR(255) NOT NULL,
[ID Cliente] VARCHAR(255) NOT NULL,
[Cliente] VARCHAR(255) NOT NULL,
[Pais Cliente] VARCHAR(255) NOT NULL,
[Cantidad] VARCHAR(255) NOT NULL,
[Venta] VARCHAR(255) NOT NULL,
[Costo] VARCHAR(255) NOT NULL); 

SELECT * FROM INFORMATION_SCHEMA.COLUMNS;


BULK INSERT #VentasTemp
FROM 'C:\Users\Flavio\Desktop\Disco\Material Docente\Eterdata Stream\SQL 360\Ventas.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ';',
    ROWTERMINATOR = '\n',   -- Usar código hexadecimal (0x0a es \n) suele ser más estable
    CODEPAGE = 'ACP',      -- 65001 es el código para UTF-8 (resuelve ñ y acentos)
	MAXERRORS = 100,          -- Permite hasta 100 errores antes de abortar
    TABLOCK
);

-- Limpieza inmediata de posibles filas vacías (Opcional pero recomendado)
DELETE FROM #VentasTemp WHERE [ID Transaccion] IS NULL OR [ID Transaccion] = ''

SELECT * FROM #VentasTemp; 

-------------------------- INSERCION DE DATOS ----------------------------

-- Insertamos registros en la tabla de Clientes
INSERT INTO Prod.Clientes
	SELECT	DISTINCT
			[ID Cliente],
			[Cliente],
			[Pais Cliente]
	FROM #VentasTemp; 

SELECT * FROM Prod.Clientes; 

-- Insertamos Registros en la tabla de Marcas
INSERT INTO Prod.Marcas
	SELECT DISTINCT
			[Marca],
			[Centro Logistico],
			CONVERT(DECIMAL(9,5),REPLACE([Latitud],',','.')) AS Lat,
			CONVERT(DECIMAL(9,5),REPLACE([Longitud],',','.')) AS Long
	FROM #VentasTemp;

SELECT * FROM Prod.Marcas; 

-- Insertamos Registros en la tabla de Productos
INSERT INTO Prod.Productos
	SELECT  T1.[ID Producto],
			T1.[Producto],
			T2.[ID Marca],
			SUM(CONVERT(INT,T1.Cantidad)) AS Stock
	FROM #VentasTemp AS T1
	LEFT JOIN Prod.Marcas AS T2
		ON T1.Marca = T2.Nombre
	-- WHERE [ID Producto] = 428
	GROUP BY T1.[ID Producto], T1.[Producto],T2.[ID Marca]; 

-- Insertamos Registros en la tabla de Mercados
SELECT * FROM Prod.Mercados; 

INSERT INTO prod.Mercados 
SELECT DISTINCT [Mercados] 
	FROM #VentasTemp; 

-- Insertamos Registros en la tabla de Vendedores
SELECT * FROM #VentasTemp;

INSERT INTO Prod.Vendedores
	SELECT DISTINCT	
			T1.[ID Vendedor],
			CONCAT(T1.[Nombre Vendedor],' ',T1.[Apellido Vendedor]) AS Vendedores,
			CAST(T1.[Fecha Nacimiento] AS DATE) AS FechaNacimiento,
			T2.[ID Region]
	FROM #VentasTemp AS T1
	LEFT JOIN Prod.Mercados AS T2
		ON T1.Mercados = T2.Nombre; 

-- Insertamos Registros en la tabla de Facturas
INSERT INTO prod.Invoice
SELECT	DISTINCT T1.[ID Factura],
				CAST(T1.[Fecha de Venta] AS DATE) AS [Fecha de Venta],
				T1.[ID Vendedor],
				T1.[ID Cliente],
				T2.[ID Region]
FROM #VentasTemp AS T1
LEFT JOIN prod.Mercados AS T2
	ON T1.Mercados = T2.Nombre;

-- Insertamos Registros en la tabla de Transacciones
INSERT INTO prod.Transacciones
SELECT	DISTINCT [ID Transaccion],
		CAST([Fecha de Recepcion] AS DATE) AS [Fecha de Recepcion],
		[ID Factura],
		[ID Producto],
		[Cantidad],
		CONVERT(DECIMAL(9,2),REPLACE([Venta],',','.')) AS [Precio Unitario],
		CONVERT(DECIMAL(9,2),REPLACE([Costo],',','.')) AS [Costo Unitario]
FROM #VentasTemp

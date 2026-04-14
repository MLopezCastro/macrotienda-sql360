-- ============================================================
--  SCRIPT 01 — CREACIÓN DE BASE DE DATOS Y TABLAS
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Naming:   Snake_Case (ID_Campo, Nombre_Campo)
-- ============================================================

-- ------------------------------------------------------------
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ------------------------------------------------------------
CREATE DATABASE Macrotienda;
GO

USE Macrotienda;
GO

-- ------------------------------------------------------------
-- 2. SCHEMA DE PRODUCCIÓN
-- ------------------------------------------------------------
CREATE SCHEMA Prod;
GO

-- ------------------------------------------------------------
-- 3. TABLAS DE DIMENSIÓN
--    Orden: de menos dependencias a más
-- ------------------------------------------------------------

-- 3.1 MERCADOS
--     Regiones comerciales donde opera la empresa.
CREATE TABLE Prod.Mercados (
    ID_Region   INT          NOT NULL IDENTITY PRIMARY KEY,
    Nombre      VARCHAR(255) NOT NULL
);
GO

-- 3.2 CLIENTES
--     Datos maestros de los clientes.
CREATE TABLE Prod.Clientes (
    ID_Cliente   INT          NOT NULL PRIMARY KEY,
    Nombre       VARCHAR(255) NOT NULL,
    Pais_Cliente VARCHAR(255) NOT NULL
);
GO

-- 3.3 MARCAS
--     Proveedores / marcas de los productos.
CREATE TABLE Prod.Marcas (
    ID_Marca          INT            NOT NULL IDENTITY PRIMARY KEY,
    Nombre            VARCHAR(255)   NOT NULL,
    Centro_Logistico  VARCHAR(255)   NOT NULL,
    Latitud           DECIMAL(9,5)   NOT NULL,
    Longitud          DECIMAL(9,5)   NOT NULL
);
GO

-- 3.4 PRODUCTOS
--     Catálogo de productos vendidos.
CREATE TABLE Prod.Productos (
    ID_Producto  INT          NOT NULL PRIMARY KEY,
    Nombre       VARCHAR(255) NOT NULL,
    ID_Marca     INT          NULL,       -- FK → Prod.Marcas
    Stock        INT          NULL
);
GO

-- 3.5 VENDEDORES
--     Equipo comercial de la organización.
CREATE TABLE Prod.Vendedores (
    ID_Vendedor      INT          NOT NULL PRIMARY KEY,
    Nombre_Vendedor  VARCHAR(255) NOT NULL,
    Fecha_Nacimiento DATE         NOT NULL,
    ID_Sucursal      INT          NULL       -- FK → Prod.Mercados
);
GO

-- ------------------------------------------------------------
-- 4. TABLAS DE HECHOS
-- ------------------------------------------------------------

-- 4.1 FACTURAS
--     Cabecera de cada venta: vincula cliente, vendedor y región.
CREATE TABLE Prod.Facturas (
    ID_Factura   INT  NOT NULL PRIMARY KEY,
    Fecha_Venta  DATE NOT NULL,
    ID_Vendedor  INT  NULL,   -- FK → Prod.Vendedores
    ID_Cliente   INT  NULL,   -- FK → Prod.Clientes
    ID_Region    INT  NULL    -- FK → Prod.Mercados
);
GO

-- 4.2 TRANSACCIONES
--     Tabla de hechos principal: detalle de cada línea de venta.
CREATE TABLE Prod.Transacciones (
    ID_Transaccion  INT            NOT NULL PRIMARY KEY,
    Fecha_Envio     DATE           NOT NULL,
    ID_Factura      INT            NULL,          -- FK → Prod.Facturas
    ID_Producto     INT            NULL,          -- FK → Prod.Productos
    Cantidad        INT            NOT NULL,
    Precio_Unitario DECIMAL(18,2)  NOT NULL,
    Costo_Unitario  DECIMAL(18,2)  NOT NULL
);
GO

-- ------------------------------------------------------------
-- 5. RELACIONES (FOREIGN KEYS)
--    Orden correcto: primero las tablas referenciadas existen.
-- ------------------------------------------------------------

-- Productos → Marcas
ALTER TABLE Prod.Productos
    ADD CONSTRAINT FK_Productos_Marcas
    FOREIGN KEY (ID_Marca) REFERENCES Prod.Marcas (ID_Marca)
    ON DELETE SET NULL
    ON UPDATE SET NULL;
GO

-- Vendedores → Mercados
ALTER TABLE Prod.Vendedores
    ADD CONSTRAINT FK_Vendedores_Mercados
    FOREIGN KEY (ID_Sucursal) REFERENCES Prod.Mercados (ID_Region)
    ON DELETE SET NULL
    ON UPDATE SET NULL;
GO

-- Facturas → Clientes
ALTER TABLE Prod.Facturas
    ADD CONSTRAINT FK_Facturas_Clientes
    FOREIGN KEY (ID_Cliente) REFERENCES Prod.Clientes (ID_Cliente)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
GO

-- Facturas → Vendedores
ALTER TABLE Prod.Facturas
    ADD CONSTRAINT FK_Facturas_Vendedores
    FOREIGN KEY (ID_Vendedor) REFERENCES Prod.Vendedores (ID_Vendedor)
    ON DELETE SET NULL
    ON UPDATE SET NULL;
GO

-- Facturas → Mercados
ALTER TABLE Prod.Facturas
    ADD CONSTRAINT FK_Facturas_Mercados
    FOREIGN KEY (ID_Region) REFERENCES Prod.Mercados (ID_Region);
GO

-- Transacciones → Facturas
ALTER TABLE Prod.Transacciones
    ADD CONSTRAINT FK_Transacciones_Facturas
    FOREIGN KEY (ID_Factura) REFERENCES Prod.Facturas (ID_Factura)
    ON DELETE SET NULL
    ON UPDATE SET NULL;
GO

-- Transacciones → Productos
ALTER TABLE Prod.Transacciones
    ADD CONSTRAINT FK_Transacciones_Productos
    FOREIGN KEY (ID_Producto) REFERENCES Prod.Productos (ID_Producto)
    ON DELETE SET NULL
    ON UPDATE SET NULL;
GO

-- ------------------------------------------------------------
-- 6. VERIFICACIÓN FINAL
-- ------------------------------------------------------------
SELECT
    t.TABLE_SCHEMA + '.' + t.TABLE_NAME  AS Tabla,
    COUNT(c.COLUMN_NAME)                 AS Cantidad_Campos
FROM INFORMATION_SCHEMA.TABLES t
JOIN INFORMATION_SCHEMA.COLUMNS c
    ON c.TABLE_SCHEMA = t.TABLE_SCHEMA
    AND c.TABLE_NAME  = t.TABLE_NAME
WHERE t.TABLE_SCHEMA = 'Prod'
GROUP BY t.TABLE_SCHEMA, t.TABLE_NAME
ORDER BY Tabla;
GO
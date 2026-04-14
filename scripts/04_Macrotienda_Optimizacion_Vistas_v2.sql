-- ============================================================
--  SCRIPT 04 — OPTIMIZACIÓN CON ÍNDICES Y VISTAS DE NEGOCIO (v2)
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Versión:  2.0 — Correcciones aplicadas (feedback Flavio)
--  Cambios:
--    · Vista 5: subqueries en JOIN reemplazadas por CTEs
-- ============================================================

USE Macrotienda;
GO

-- ============================================================
--  PARTE 1 — OPTIMIZACIÓN CON ÍNDICES
--  (Sin cambios respecto a v1 — índices aprobados por Flavio)
-- ============================================================

-- Limpia caché del plan de ejecución y buffers antes de medir
-- (ejecutar manualmente antes de cada bloque de auditoría)
-- DBCC FREEPROCCACHE;
-- DBCC DROPCLEANBUFFERS;

-- ============================================================
--  ÍNDICE 1 — Consigna 3: Utilidad bruta mensual
--  Columna clave: Fecha_Venta en Prod.Facturas
-- ============================================================

SET STATISTICS TIME ON;

SELECT
    YEAR(f.Fecha_Venta)            AS Anio,
    MONTH(f.Fecha_Venta)           AS Mes_Numero,
    DATENAME(MONTH, f.Fecha_Venta) AS Mes_Nombre,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2) AS Ingreso_Total,
    ROUND(SUM(t.Costo_Unitario  * t.Cantidad), 2) AS Costo_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta
FROM Prod.Transacciones t
INNER JOIN Prod.Facturas f ON f.ID_Factura = t.ID_Factura
WHERE YEAR(f.Fecha_Venta)  = 2016
  AND MONTH(f.Fecha_Venta) BETWEEN 1 AND 3
GROUP BY YEAR(f.Fecha_Venta), MONTH(f.Fecha_Venta),
         DATENAME(MONTH, f.Fecha_Venta)
ORDER BY Mes_Numero;

SET STATISTICS TIME OFF;
GO

CREATE INDEX idx_Facturas_Fecha_Venta
    ON Prod.Facturas (Fecha_Venta)
    INCLUDE (ID_Factura, ID_Vendedor, ID_Cliente, ID_Region);
GO

SET STATISTICS TIME ON;

SELECT
    YEAR(f.Fecha_Venta)            AS Anio,
    MONTH(f.Fecha_Venta)           AS Mes_Numero,
    DATENAME(MONTH, f.Fecha_Venta) AS Mes_Nombre,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2) AS Ingreso_Total,
    ROUND(SUM(t.Costo_Unitario  * t.Cantidad), 2) AS Costo_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta
FROM Prod.Transacciones t
INNER JOIN Prod.Facturas f ON f.ID_Factura = t.ID_Factura
WHERE YEAR(f.Fecha_Venta)  = 2016
  AND MONTH(f.Fecha_Venta) BETWEEN 1 AND 3
GROUP BY YEAR(f.Fecha_Venta), MONTH(f.Fecha_Venta),
         DATENAME(MONTH, f.Fecha_Venta)
ORDER BY Mes_Numero;

SET STATISTICS TIME OFF;
GO

-- ============================================================
--  ÍNDICE 2 — Consigna 5: Análisis comparativo por mercado
--  Columna clave: ID_Region en Prod.Facturas
-- ============================================================

SET STATISTICS TIME ON;

SELECT
    m.Nombre                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)   AS Total_Facturas,
    COUNT(DISTINCT f.ID_Cliente)   AS Clientes_Unicos,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta,
    ROUND(
        (SUM(t.Precio_Unitario * t.Cantidad)
       - SUM(t.Costo_Unitario  * t.Cantidad))
      / SUM(SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad))
        OVER () * 100
    , 2)                           AS Participacion_Porcentual
FROM Prod.Facturas f
INNER JOIN Prod.Mercados      m ON m.ID_Region  = f.ID_Region
INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
GROUP BY m.ID_Region, m.Nombre
ORDER BY Utilidad_Bruta DESC;

SET STATISTICS TIME OFF;
GO

CREATE INDEX idx_Facturas_ID_Region
    ON Prod.Facturas (ID_Region)
    INCLUDE (ID_Factura, ID_Cliente, ID_Vendedor, Fecha_Venta);
GO

SET STATISTICS TIME ON;

SELECT
    m.Nombre                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)   AS Total_Facturas,
    COUNT(DISTINCT f.ID_Cliente)   AS Clientes_Unicos,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta,
    ROUND(
        (SUM(t.Precio_Unitario * t.Cantidad)
       - SUM(t.Costo_Unitario  * t.Cantidad))
      / SUM(SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad))
        OVER () * 100
    , 2)                           AS Participacion_Porcentual
FROM Prod.Facturas f
INNER JOIN Prod.Mercados      m ON m.ID_Region  = f.ID_Region
INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
GROUP BY m.ID_Region, m.Nombre
ORDER BY Utilidad_Bruta DESC;

SET STATISTICS TIME OFF;
GO

-- ============================================================
--  ÍNDICE 3 — Consigna 6: Actividad comercial por vendedor
--  Columna clave: ID_Vendedor en Prod.Facturas
-- ============================================================

SET STATISTICS TIME ON;

SELECT
    v.Nombre_Vendedor              AS Vendedor,
    m.Nombre                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)   AS Cantidad_Facturas,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      / COUNT(DISTINCT f.ID_Factura)
    , 2)                           AS Ticket_Promedio,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta
FROM Prod.Vendedores v
INNER JOIN Prod.Mercados      m ON m.ID_Region   = v.ID_Sucursal
INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
GROUP BY v.ID_Vendedor, v.Nombre_Vendedor, m.ID_Region, m.Nombre
HAVING COUNT(DISTINCT f.ID_Factura) > 50
ORDER BY Utilidad_Bruta DESC;

SET STATISTICS TIME OFF;
GO

CREATE INDEX idx_Facturas_ID_Vendedor
    ON Prod.Facturas (ID_Vendedor)
    INCLUDE (ID_Factura, ID_Cliente, ID_Region, Fecha_Venta);
GO

SET STATISTICS TIME ON;

SELECT
    v.Nombre_Vendedor              AS Vendedor,
    m.Nombre                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)   AS Cantidad_Facturas,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      / COUNT(DISTINCT f.ID_Factura)
    , 2)                           AS Ticket_Promedio,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                           AS Utilidad_Bruta
FROM Prod.Vendedores v
INNER JOIN Prod.Mercados      m ON m.ID_Region   = v.ID_Sucursal
INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
GROUP BY v.ID_Vendedor, v.Nombre_Vendedor, m.ID_Region, m.Nombre
HAVING COUNT(DISTINCT f.ID_Factura) > 50
ORDER BY Utilidad_Bruta DESC;

SET STATISTICS TIME OFF;
GO

-- ============================================================
--  ÍNDICE 4 — Consigna 8: Análisis LAG Febrero 2016
--  Columna clave: ID_Factura en Prod.Transacciones
-- ============================================================

SET STATISTICS TIME ON;

WITH Utilidad_Diaria AS (
    SELECT
        f.Fecha_Venta              AS Fecha,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                       AS Utilidad_Bruta
    FROM Prod.Facturas f
    INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
    WHERE YEAR(f.Fecha_Venta) = 2016 AND MONTH(f.Fecha_Venta) = 2
    GROUP BY f.Fecha_Venta
),
Con_LAG AS (
    SELECT
        Fecha,
        Utilidad_Bruta,
        LAG(Utilidad_Bruta) OVER (ORDER BY Fecha) AS Utilidad_Dia_Anterior
    FROM Utilidad_Diaria
)
SELECT
    Fecha,
    Utilidad_Bruta                                         AS Utilidad_Dia_Actual,
    Utilidad_Dia_Anterior,
    ROUND(Utilidad_Bruta - Utilidad_Dia_Anterior, 2)      AS Variacion_Absoluta,
    CASE
        WHEN Utilidad_Dia_Anterior IS NULL                THEN '-'
        WHEN Utilidad_Bruta > Utilidad_Dia_Anterior       THEN 'Subio'
        WHEN Utilidad_Bruta < Utilidad_Dia_Anterior       THEN 'Bajo'
        ELSE 'Se Mantuvo'
    END                                                    AS Tendencia
FROM Con_LAG
ORDER BY Fecha;

SET STATISTICS TIME OFF;
GO

CREATE INDEX idx_Transacciones_ID_Factura
    ON Prod.Transacciones (ID_Factura)
    INCLUDE (ID_Producto, Cantidad, Precio_Unitario, Costo_Unitario);
GO

SET STATISTICS TIME ON;

WITH Utilidad_Diaria AS (
    SELECT
        f.Fecha_Venta              AS Fecha,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                       AS Utilidad_Bruta
    FROM Prod.Facturas f
    INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
    WHERE YEAR(f.Fecha_Venta) = 2016 AND MONTH(f.Fecha_Venta) = 2
    GROUP BY f.Fecha_Venta
),
Con_LAG AS (
    SELECT
        Fecha,
        Utilidad_Bruta,
        LAG(Utilidad_Bruta) OVER (ORDER BY Fecha) AS Utilidad_Dia_Anterior
    FROM Utilidad_Diaria
)
SELECT
    Fecha,
    Utilidad_Bruta                                         AS Utilidad_Dia_Actual,
    Utilidad_Dia_Anterior,
    ROUND(Utilidad_Bruta - Utilidad_Dia_Anterior, 2)      AS Variacion_Absoluta,
    CASE
        WHEN Utilidad_Dia_Anterior IS NULL                THEN '-'
        WHEN Utilidad_Bruta > Utilidad_Dia_Anterior       THEN 'Subio'
        WHEN Utilidad_Bruta < Utilidad_Dia_Anterior       THEN 'Bajo'
        ELSE 'Se Mantuvo'
    END                                                    AS Tendencia
FROM Con_LAG
ORDER BY Fecha;

SET STATISTICS TIME OFF;
GO

-- ============================================================
--  ÍNDICE 5 — Consigna 9: Ranking de vendedores
--  Columna clave: ID_Producto en Prod.Transacciones
-- ============================================================

SET STATISTICS TIME ON;

WITH Utilidad_Por_Vendedor AS (
    SELECT
        v.ID_Vendedor,
        v.Nombre_Vendedor          AS Vendedor,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                       AS Utilidad_Bruta
    FROM Prod.Vendedores v
    INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
    INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
    GROUP BY v.ID_Vendedor, v.Nombre_Vendedor
)
SELECT
    ROW_NUMBER() OVER (ORDER BY Utilidad_Bruta DESC) AS Ranking,
    Vendedor,
    Utilidad_Bruta,
    ROUND(Utilidad_Bruta / SUM(Utilidad_Bruta) OVER () * 100, 2) AS Participacion_Porcentual,
    ROUND(
        SUM(Utilidad_Bruta) OVER (ORDER BY Utilidad_Bruta DESC)
      / SUM(Utilidad_Bruta) OVER () * 100
    , 2)                           AS Acumulado_Porcentual
FROM Utilidad_Por_Vendedor
ORDER BY Ranking;

SET STATISTICS TIME OFF;
GO

CREATE INDEX idx_Transacciones_ID_Producto
    ON Prod.Transacciones (ID_Producto)
    INCLUDE (ID_Factura, Cantidad, Precio_Unitario, Costo_Unitario);
GO

SET STATISTICS TIME ON;

WITH Utilidad_Por_Vendedor AS (
    SELECT
        v.ID_Vendedor,
        v.Nombre_Vendedor          AS Vendedor,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                       AS Utilidad_Bruta
    FROM Prod.Vendedores v
    INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
    INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
    GROUP BY v.ID_Vendedor, v.Nombre_Vendedor
)
SELECT
    ROW_NUMBER() OVER (ORDER BY Utilidad_Bruta DESC) AS Ranking,
    Vendedor,
    Utilidad_Bruta,
    ROUND(Utilidad_Bruta / SUM(Utilidad_Bruta) OVER () * 100, 2) AS Participacion_Porcentual,
    ROUND(
        SUM(Utilidad_Bruta) OVER (ORDER BY Utilidad_Bruta DESC)
      / SUM(Utilidad_Bruta) OVER () * 100
    , 2)                           AS Acumulado_Porcentual
FROM Utilidad_Por_Vendedor
ORDER BY Ranking;

SET STATISTICS TIME OFF;
GO

-- ============================================================
--  PARTE 2 — VISTAS DE NEGOCIO
-- ============================================================

-- ============================================================
--  VISTA 1 — Rentabilidad por Producto (sin cambios)
-- ============================================================

CREATE OR ALTER VIEW Prod.V_Rentabilidad_Producto AS
SELECT
    p.ID_Producto,
    p.Nombre                                                AS Producto,
    mk.Nombre                                               AS Marca,
    ROUND(AVG(t.Precio_Unitario), 2)                       AS Precio_Promedio,
    ROUND(AVG(t.Costo_Unitario),  2)                       AS Costo_Promedio,
    ROUND(AVG(t.Precio_Unitario) - AVG(t.Costo_Unitario), 2) AS Ganancia_Promedio,
    ROUND(
        (AVG(t.Precio_Unitario) - AVG(t.Costo_Unitario))
        / AVG(t.Precio_Unitario) * 100
    , 2)                                                    AS Margen_Porcentual,
    p.Stock
FROM Prod.Transacciones t
INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
INNER JOIN Prod.Marcas mk   ON mk.ID_Marca   = p.ID_Marca
GROUP BY p.ID_Producto, p.Nombre, mk.Nombre, p.Stock;
GO

-- ============================================================
--  VISTA 2 — Resumen de Ventas por Mercado (sin cambios)
-- ============================================================

CREATE OR ALTER VIEW Prod.V_Ventas_Por_Mercado AS
SELECT
    m.Nombre                                                AS Mercado,
    COUNT(DISTINCT f.ID_Factura)                            AS Total_Facturas,
    COUNT(DISTINCT f.ID_Cliente)                            AS Clientes_Unicos,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)          AS Ingreso_Total,
    ROUND(SUM(t.Costo_Unitario  * t.Cantidad), 2)          AS Costo_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                    AS Utilidad_Bruta
FROM Prod.Facturas f
INNER JOIN Prod.Mercados      m ON m.ID_Region  = f.ID_Region
INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
GROUP BY m.ID_Region, m.Nombre;
GO

-- ============================================================
--  VISTA 3 — Performance de Vendedores (sin cambios)
-- ============================================================

CREATE OR ALTER VIEW Prod.V_Performance_Vendedores AS
SELECT
    v.ID_Vendedor,
    v.Nombre_Vendedor                                       AS Vendedor,
    m.Nombre                                                AS Mercado,
    COUNT(DISTINCT f.ID_Factura)                            AS Cantidad_Facturas,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      / COUNT(DISTINCT f.ID_Factura)
    , 2)                                                    AS Ticket_Promedio,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)          AS Ingreso_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                    AS Utilidad_Bruta
FROM Prod.Vendedores v
INNER JOIN Prod.Mercados      m ON m.ID_Region   = v.ID_Sucursal
INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
GROUP BY v.ID_Vendedor, v.Nombre_Vendedor, m.ID_Region, m.Nombre;
GO

-- ============================================================
--  VISTA 4 — Segmentación de Clientes (sin cambios)
-- ============================================================

CREATE OR ALTER VIEW Prod.V_Segmentacion_Clientes AS
SELECT
    c.ID_Cliente,
    c.Nombre                                                AS Cliente,
    c.Pais_Cliente,
    COUNT(f.ID_Factura)                                     AS Cantidad_Facturas,
    CASE
        WHEN COUNT(f.ID_Factura) >= 20             THEN 'PREMIUM'
        WHEN COUNT(f.ID_Factura) BETWEEN 5 AND 19  THEN 'STANDARD'
        ELSE                                            'Nuevos'
    END                                                     AS Segmento
FROM Prod.Clientes c
INNER JOIN Prod.Facturas f ON f.ID_Cliente = c.ID_Cliente
GROUP BY c.ID_Cliente, c.Nombre, c.Pais_Cliente;
GO

-- ============================================================
--  VISTA 5 — Inventario Valorizado por Marca (CORREGIDA)
--  Público: Logística / Finanzas
--  CORRECCIÓN: las subqueries en el JOIN se reemplazaron por
--  CTEs nombrados. Esto mejora la legibilidad del código y
--  permite al optimizador de SQL Server generar un plan de
--  ejecución más eficiente al materializar cada CTE por
--  separado antes de hacer los JOINs.
-- ============================================================

CREATE OR ALTER VIEW Prod.V_Inventario_Por_Marca AS
WITH Stock_Por_Marca AS (
    -- Stock real: suma directa desde Productos
    -- sin tocar Transacciones para evitar duplicación.
    SELECT
        ID_Marca,
        SUM(Stock) AS Stock_Total
    FROM Prod.Productos
    GROUP BY ID_Marca
),
Costo_Por_Marca AS (
    -- Costo unitario promedio histórico por marca
    -- calculado desde Transacciones de forma independiente.
    SELECT
        p.ID_Marca,
        AVG(t.Costo_Unitario) AS Costo_Promedio
    FROM Prod.Transacciones t
    INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
    GROUP BY p.ID_Marca
)
SELECT
    mk.Nombre                                               AS Marca,
    mk.Centro_Logistico,
    s.Stock_Total,
    ROUND(c.Costo_Promedio, 2)                             AS Costo_Unitario_Promedio,
    ROUND(c.Costo_Promedio * s.Stock_Total, 2)             AS Costo_Total_Inventario
FROM Prod.Marcas mk
INNER JOIN Stock_Por_Marca s ON s.ID_Marca = mk.ID_Marca
INNER JOIN Costo_Por_Marca c ON c.ID_Marca = mk.ID_Marca;
GO

-- ============================================================
--  VERIFICACIÓN FINAL
-- ============================================================

SELECT
    i.name                         AS Indice,
    t.name                         AS Tabla,
    i.type_desc                    AS Tipo
FROM sys.indexes i
INNER JOIN sys.tables t ON t.object_id = i.object_id
WHERE t.schema_id = SCHEMA_ID('Prod')
  AND i.type > 0
ORDER BY Tabla, Indice;
GO

SELECT
    TABLE_SCHEMA + '.' + TABLE_NAME AS Vista
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'Prod'
ORDER BY TABLE_NAME;
GO

SELECT TOP 5 * FROM Prod.V_Rentabilidad_Producto   ORDER BY Margen_Porcentual DESC;
SELECT TOP 5 * FROM Prod.V_Ventas_Por_Mercado       ORDER BY Utilidad_Bruta DESC;
SELECT TOP 5 * FROM Prod.V_Performance_Vendedores   ORDER BY Utilidad_Bruta DESC;
SELECT TOP 5 * FROM Prod.V_Segmentacion_Clientes    ORDER BY Cantidad_Facturas DESC;
SELECT TOP 5 * FROM Prod.V_Inventario_Por_Marca     ORDER BY Costo_Total_Inventario DESC;
GO

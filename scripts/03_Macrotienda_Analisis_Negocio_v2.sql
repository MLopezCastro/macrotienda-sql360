-- ============================================================
--  SCRIPT 03 — ANÁLISIS DE NEGOCIO (v2)
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Versión:  2.0 — Correcciones aplicadas (feedback Flavio)
--  Cambios:
--    · Query 1: NULLIF en divisor → evita error si Precio = 0
--    · Query 8: LAG calculado una sola vez en CTE intermedio
-- ============================================================

USE Macrotienda;
GO

-- ============================================================
--  CONSIGNA 1
--  Margen de ganancia por producto.
--  Fórmula: (Precio - Costo) / Precio * 100
--  Fuente:  Prod.Transacciones + Prod.Productos
--  CORRECCIÓN: NULLIF(AVG(Precio_Unitario), 0) evita división
--  por cero en caso que algún producto tenga Precio = 0.
-- ============================================================

SELECT
    p.ID_Producto,
    p.Nombre                                                        AS Producto,
    ROUND(AVG(t.Precio_Unitario), 2)                               AS Precio_Promedio,
    ROUND(AVG(t.Costo_Unitario),  2)                               AS Costo_Promedio,
    ROUND(AVG(t.Precio_Unitario) - AVG(t.Costo_Unitario), 2)      AS Ganancia_Promedio,
    ROUND(
        (AVG(t.Precio_Unitario) - AVG(t.Costo_Unitario))
        / NULLIF(AVG(t.Precio_Unitario), 0) * 100               -- NULLIF evita división por cero
    , 2)                                                           AS Margen_Porcentual
FROM Prod.Transacciones t
INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
GROUP BY p.ID_Producto, p.Nombre
ORDER BY Margen_Porcentual DESC;
GO

-- ============================================================
--  CONSIGNA 2
--  Costo total de inventario por marca.
--  Fórmula: Costo_Unitario_Promedio * Stock_Total
--  Corrección: el Stock se calcula en subquery independiente
--  para evitar multiplicación por cantidad de transacciones.
--  Fuente:  Prod.Productos + Prod.Marcas + Prod.Transacciones
-- ============================================================

SELECT
    mk.Nombre                                                      AS Marca,
    s.Stock_Total,
    ROUND(c.Costo_Promedio, 2)                                    AS Costo_Unitario_Promedio,
    ROUND(c.Costo_Promedio * s.Stock_Total, 2)                    AS Costo_Total_Inventario
FROM Prod.Marcas mk
INNER JOIN (
    -- Stock real por marca: suma directa desde Productos,
    -- sin joinear Transacciones para evitar duplicación.
    SELECT   ID_Marca, SUM(Stock) AS Stock_Total
    FROM     Prod.Productos
    GROUP BY ID_Marca
) s ON s.ID_Marca = mk.ID_Marca
INNER JOIN (
    -- Costo unitario promedio histórico por marca,
    -- calculado desde Transacciones de forma independiente.
    SELECT   p.ID_Marca, AVG(t.Costo_Unitario) AS Costo_Promedio
    FROM     Prod.Transacciones t
    INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
    GROUP BY p.ID_Marca
) c ON c.ID_Marca = mk.ID_Marca
ORDER BY Costo_Total_Inventario DESC;
GO

-- ============================================================
--  CONSIGNA 3
--  Utilidad bruta mensual — primeros 3 meses de 2016.
--  Fórmula: Ingreso_Total - Costo_Total
--           donde Ingreso = Precio_Unitario * Cantidad
--                 Costo   = Costo_Unitario  * Cantidad
--  Fuente:  Prod.Transacciones + Prod.Facturas
-- ============================================================

SELECT
    YEAR(f.Fecha_Venta)                                           AS Anio,
    MONTH(f.Fecha_Venta)                                          AS Mes_Numero,
    DATENAME(MONTH, f.Fecha_Venta)                                AS Mes_Nombre,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)                 AS Ingreso_Total,
    ROUND(SUM(t.Costo_Unitario  * t.Cantidad), 2)                 AS Costo_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                          AS Utilidad_Bruta
FROM Prod.Transacciones t
INNER JOIN Prod.Facturas f ON f.ID_Factura = t.ID_Factura
WHERE YEAR(f.Fecha_Venta)  = 2016
  AND MONTH(f.Fecha_Venta) BETWEEN 1 AND 3
GROUP BY
    YEAR(f.Fecha_Venta),
    MONTH(f.Fecha_Venta),
    DATENAME(MONTH, f.Fecha_Venta)
ORDER BY Mes_Numero;
GO

-- ============================================================
--  CONSIGNA 4
--  Margen de ganancia por proveedor (Marca).
--  Muestra: Ingreso total, Costo total, Utilidad bruta,
--           Margen porcentual.
--  Fuente:  Prod.Transacciones + Prod.Productos + Prod.Marcas
-- ============================================================

SELECT
    mk.Nombre                                                      AS Marca,
    ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)                 AS Ingreso_Total,
    ROUND(SUM(t.Costo_Unitario  * t.Cantidad), 2)                 AS Costo_Total,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                          AS Utilidad_Bruta,
    ROUND(
        (SUM(t.Precio_Unitario * t.Cantidad)
       - SUM(t.Costo_Unitario  * t.Cantidad))
      /  SUM(t.Precio_Unitario * t.Cantidad) * 100
    , 2)                                                          AS Margen_Porcentual
FROM Prod.Transacciones t
INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
INNER JOIN Prod.Marcas mk   ON mk.ID_Marca   = p.ID_Marca
GROUP BY mk.ID_Marca, mk.Nombre
ORDER BY Margen_Porcentual DESC;
GO

-- ============================================================
--  CONSIGNA 5
--  Análisis comparativo por mercado.
--  Muestra: Facturas emitidas, Clientes únicos, Utilidad bruta
--           y % de participación sobre el total del negocio.
--  Fuente:  Prod.Facturas + Prod.Transacciones + Prod.Mercados
-- ============================================================

SELECT
    m.Nombre                                                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)                                   AS Total_Facturas,
    COUNT(DISTINCT f.ID_Cliente)                                   AS Clientes_Unicos,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                           AS Utilidad_Bruta,
    ROUND(
        (SUM(t.Precio_Unitario * t.Cantidad)
       - SUM(t.Costo_Unitario  * t.Cantidad))
      / SUM(SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad))
        OVER () * 100
    , 2)                                                           AS Participacion_Porcentual
FROM Prod.Facturas f
INNER JOIN Prod.Mercados     m ON m.ID_Region  = f.ID_Region
INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
GROUP BY m.ID_Region, m.Nombre
ORDER BY Utilidad_Bruta DESC;
GO

-- ============================================================
--  CONSIGNA 6
--  Actividad comercial por vendedor en su mercado.
--  Filtra vendedores con más de 50 facturas gestionadas.
--  Muestra: Mercado, Facturas, Ticket promedio, Utilidad bruta.
--  Fuente:  Prod.Vendedores + Prod.Facturas + Prod.Transacciones
--           + Prod.Mercados
-- ============================================================

SELECT
    v.Nombre_Vendedor                                              AS Vendedor,
    m.Nombre                                                       AS Mercado,
    COUNT(DISTINCT f.ID_Factura)                                   AS Cantidad_Facturas,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      / COUNT(DISTINCT f.ID_Factura)
    , 2)                                                           AS Ticket_Promedio,
    ROUND(
        SUM(t.Precio_Unitario * t.Cantidad)
      - SUM(t.Costo_Unitario  * t.Cantidad)
    , 2)                                                           AS Utilidad_Bruta
FROM Prod.Vendedores v
INNER JOIN Prod.Mercados      m ON m.ID_Region  = v.ID_Sucursal
INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
GROUP BY v.ID_Vendedor, v.Nombre_Vendedor, m.ID_Region, m.Nombre
HAVING COUNT(DISTINCT f.ID_Factura) > 50
ORDER BY Utilidad_Bruta DESC;
GO

-- ============================================================
--  CONSIGNA 7
--  Segmentación de clientes con CTE.
--  Segmentos:
--    PREMIUM  → 20 o más facturas
--    STANDARD → entre 5 y 19 facturas
--    Nuevos   → hasta 4 facturas
--  Muestra: cantidad de clientes por segmento.
--  Fuente:  Prod.Clientes + Prod.Facturas
-- ============================================================

WITH Compras_Por_Cliente AS (
    SELECT
        c.ID_Cliente,
        c.Nombre                         AS Cliente,
        COUNT(f.ID_Factura)              AS Cantidad_Compras
    FROM Prod.Clientes c
    INNER JOIN Prod.Facturas f ON f.ID_Cliente = c.ID_Cliente
    GROUP BY c.ID_Cliente, c.Nombre
),
Segmentados AS (
    SELECT
        ID_Cliente,
        Cliente,
        Cantidad_Compras,
        CASE
            WHEN Cantidad_Compras >= 20              THEN 'PREMIUM'
            WHEN Cantidad_Compras BETWEEN 5 AND 19   THEN 'STANDARD'
            ELSE                                          'Nuevos'
        END AS Segmento
    FROM Compras_Por_Cliente
)
SELECT
    Segmento,
    COUNT(*) AS Cantidad_Clientes
FROM Segmentados
GROUP BY Segmento
ORDER BY
    CASE Segmento
        WHEN 'PREMIUM'  THEN 1
        WHEN 'STANDARD' THEN 2
        WHEN 'Nuevos'   THEN 3
    END;
GO

-- ============================================================
--  CONSIGNA 8
--  Análisis día a día de Utilidad Bruta — Febrero 2016.
--  Fuente:  Prod.Facturas + Prod.Transacciones
--  CORRECCIÓN: LAG se calcula UNA SOLA VEZ en el CTE
--  intermedio "Con_LAG" y luego se reutiliza en el SELECT
--  final. Esto evita que la función de ventana se ejecute
--  3 veces, reduciendo el consumo de memoria RAM.
-- ============================================================

WITH Utilidad_Diaria AS (
    -- Paso 1: calcular utilidad bruta por día
    SELECT
        f.Fecha_Venta                                              AS Fecha,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                                                       AS Utilidad_Bruta
    FROM Prod.Facturas f
    INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
    WHERE YEAR(f.Fecha_Venta)  = 2016
      AND MONTH(f.Fecha_Venta) = 2
    GROUP BY f.Fecha_Venta
),
Con_LAG AS (
    -- Paso 2: calcular LAG una sola vez y almacenarlo
    SELECT
        Fecha,
        Utilidad_Bruta,
        LAG(Utilidad_Bruta) OVER (ORDER BY Fecha)                 AS Utilidad_Dia_Anterior
    FROM Utilidad_Diaria
)
-- Paso 3: reutilizar Utilidad_Dia_Anterior sin recalcular LAG
SELECT
    Fecha,
    Utilidad_Bruta                                                 AS Utilidad_Dia_Actual,
    Utilidad_Dia_Anterior,
    ROUND(
        Utilidad_Bruta - Utilidad_Dia_Anterior
    , 2)                                                           AS Variacion_Absoluta,
    CASE
        WHEN Utilidad_Dia_Anterior IS NULL                        THEN '—'
        WHEN Utilidad_Bruta > Utilidad_Dia_Anterior               THEN 'Subió'
        WHEN Utilidad_Bruta < Utilidad_Dia_Anterior               THEN 'Bajó'
        ELSE                                                           'Se Mantuvo'
    END                                                            AS Tendencia
FROM Con_LAG
ORDER BY Fecha;
GO

-- ============================================================
--  CONSIGNA 9
--  Ranking de vendedores por contribución a la Utilidad Bruta.
--  Usa CTE + función de ventana SUM() OVER().
--  Muestra: Utilidad por vendedor, % de participación,
--           ranking de mayor a menor contribución.
--  Fuente:  Prod.Vendedores + Prod.Facturas + Prod.Transacciones
-- ============================================================

WITH Utilidad_Por_Vendedor AS (
    SELECT
        v.ID_Vendedor,
        v.Nombre_Vendedor                                          AS Vendedor,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                                                       AS Utilidad_Bruta
    FROM Prod.Vendedores v
    INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
    INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
    GROUP BY v.ID_Vendedor, v.Nombre_Vendedor
)
SELECT
    ROW_NUMBER() OVER (ORDER BY Utilidad_Bruta DESC)              AS Ranking,
    Vendedor,
    Utilidad_Bruta,
    ROUND(
        Utilidad_Bruta
      / SUM(Utilidad_Bruta) OVER () * 100
    , 2)                                                          AS Participacion_Porcentual,
    ROUND(
        SUM(Utilidad_Bruta) OVER (ORDER BY Utilidad_Bruta DESC)
      / SUM(Utilidad_Bruta) OVER () * 100
    , 2)                                                          AS Acumulado_Porcentual
FROM Utilidad_Por_Vendedor
ORDER BY Ranking;
GO

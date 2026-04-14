
-- ============================================================
--  SCRIPT 05 — FUNCIONES DEFINIDAS POR USUARIO (UDFs)
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Consigna: 5 — Implementación de Funciones
-- ============================================================
--
--  4 funciones escalares (READS SQL DATA):
--    1. fn_Margen_Por_Transaccion   (2 parámetros)
--    2. fn_Edad_Vendedor            (1 parámetro)
--    3. fn_Disponibilidad_Stock     (2 parámetros)
--    4. fn_Ticket_Promedio_Cliente  (1 parámetro)
-- ============================================================
 
USE Macrotienda;
GO
 
-- ============================================================
--  FUNCIÓN 1 — Margen de Utilidad por Transacción
--  Parámetros: @ID_Producto, @ID_Transaccion
--  Retorna:    DECIMAL — ganancia neta de la línea de venta
--              calculada como (Precio - Costo) * Cantidad
-- ============================================================
 
CREATE OR ALTER FUNCTION Prod.fn_Margen_Por_Transaccion
(
    @ID_Producto    INT,
    @ID_Transaccion INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Margen DECIMAL(18,2);
 
    SELECT @Margen = (t.Precio_Unitario - t.Costo_Unitario) * t.Cantidad
    FROM Prod.Transacciones t
    WHERE t.ID_Transaccion = @ID_Transaccion
      AND t.ID_Producto    = @ID_Producto;
 
    -- Si no existe la combinación, retorna NULL
    RETURN @Margen;
END;
GO
 
-- Prueba:
SELECT
    t.ID_Transaccion,
    t.ID_Producto,
    t.Precio_Unitario,
    t.Costo_Unitario,
    t.Cantidad,
    Prod.fn_Margen_Por_Transaccion(t.ID_Producto, t.ID_Transaccion) AS Margen_Neto
FROM Prod.Transacciones t
WHERE t.ID_Transaccion BETWEEN 24078 AND 24090
ORDER BY t.ID_Transaccion;
GO
 
-- ============================================================
--  FUNCIÓN 2 — Edad del Vendedor
--  Parámetro: @ID_Vendedor
--  Retorna:   INT — edad actual en años calculada desde
--             Fecha_Nacimiento hasta hoy
-- ============================================================
 
CREATE OR ALTER FUNCTION Prod.fn_Edad_Vendedor
(
    @ID_Vendedor INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Edad INT;
 
    SELECT @Edad = DATEDIFF(YEAR, v.Fecha_Nacimiento, GETDATE())
                 - CASE
                       WHEN MONTH(v.Fecha_Nacimiento) > MONTH(GETDATE())
                         OR (MONTH(v.Fecha_Nacimiento) = MONTH(GETDATE())
                            AND DAY(v.Fecha_Nacimiento) > DAY(GETDATE()))
                       THEN 1
                       ELSE 0
                   END
    FROM Prod.Vendedores v
    WHERE v.ID_Vendedor = @ID_Vendedor;
 
    RETURN @Edad;
END;
GO
 
-- Prueba: edad de todos los vendedores
SELECT
    ID_Vendedor,
    Nombre_Vendedor,
    Fecha_Nacimiento,
    Prod.fn_Edad_Vendedor(ID_Vendedor) AS Edad_Actual
FROM Prod.Vendedores
ORDER BY Edad_Actual DESC;
GO
 
-- ============================================================
--  FUNCIÓN 3 — Disponibilidad de Stock por Marca
--  Parámetros: @ID_Marca, @Stock_Minimo
--  Retorna:    VARCHAR — 'Suficiente' si el stock total de
--              la marca supera el mínimo, 'Crítico' si no
-- ============================================================
 
CREATE OR ALTER FUNCTION Prod.fn_Disponibilidad_Stock
(
    @ID_Marca     INT,
    @Stock_Minimo INT
)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Stock_Total INT;
    DECLARE @Resultado   VARCHAR(20);
 
    SELECT @Stock_Total = SUM(p.Stock)
    FROM Prod.Productos p
    WHERE p.ID_Marca = @ID_Marca;
 
    SET @Resultado = CASE
                         WHEN @Stock_Total >= @Stock_Minimo THEN 'Suficiente'
                         ELSE 'Crítico'
                     END;
 
    RETURN @Resultado;
END;
GO
 
-- Prueba: estado de stock de todas las marcas con mínimo de 50.000 unidades
SELECT
    mk.ID_Marca,
    mk.Nombre                                          AS Marca,
    SUM(p.Stock)                                       AS Stock_Total,
    Prod.fn_Disponibilidad_Stock(mk.ID_Marca, 50000)  AS Estado_Stock
FROM Prod.Marcas mk
INNER JOIN Prod.Productos p ON p.ID_Marca = mk.ID_Marca
GROUP BY mk.ID_Marca, mk.Nombre
ORDER BY Stock_Total DESC;
GO
 
-- ============================================================
--  FUNCIÓN 4 — Ticket Promedio por Cliente
--  Parámetro: @ID_Cliente
--  Retorna:   DECIMAL — ingreso total del cliente dividido
--             por su cantidad de facturas únicas
-- ============================================================
 
CREATE OR ALTER FUNCTION Prod.fn_Ticket_Promedio_Cliente
(
    @ID_Cliente INT
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Ticket_Promedio DECIMAL(18,2);
 
    SELECT @Ticket_Promedio =
        SUM(t.Precio_Unitario * t.Cantidad)
        / NULLIF(COUNT(DISTINCT f.ID_Factura), 0)
    FROM Prod.Facturas f
    INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
    WHERE f.ID_Cliente = @ID_Cliente;
 
    RETURN @Ticket_Promedio;
END;
GO
 
-- Prueba: ticket promedio de todos los clientes
SELECT
    c.ID_Cliente,
    c.Nombre                                              AS Cliente,
    c.Pais_Cliente,
    Prod.fn_Ticket_Promedio_Cliente(c.ID_Cliente)        AS Ticket_Promedio
FROM Prod.Clientes c
ORDER BY Ticket_Promedio DESC;
GO
 
-- ============================================================
--  VERIFICACIÓN FINAL — funciones creadas en schema Prod
-- ============================================================
SELECT
    ROUTINE_SCHEMA + '.' + ROUTINE_NAME  AS Funcion,
    ROUTINE_TYPE                          AS Tipo,
    DATA_TYPE                             AS Retorna
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'Prod'
  AND ROUTINE_TYPE   = 'FUNCTION'
ORDER BY ROUTINE_NAME;
GO

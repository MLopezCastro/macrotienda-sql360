
-- ============================================================
--  SCRIPT 06 — STORED PROCEDURES
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Consigna: 6 — Procedimientos Almacenados
-- ============================================================
--
--  3 Stored Procedures:
--    1. sp_Actualizar_Precios_Por_Marca   (2 parámetros)
--    2. sp_Reporte_Rendimiento_Mercado    (1 parámetro)
--    3. sp_Baja_Producto_Con_Validacion   (1 parámetro)
-- ============================================================
 
USE Macrotienda;
GO
 
-- ============================================================
--  SP 1 — Actualización de Precios por Marca
--  Parámetros: @ID_Marca, @Porcentaje_Incremento
--  Lógica:     Actualiza el Precio_Unitario de todas las
--              transacciones asociadas a productos de la marca
--              aplicando el porcentaje de incremento indicado.
--              Usa transacción para garantizar consistencia.
-- ============================================================
 
CREATE OR ALTER PROCEDURE Prod.sp_Actualizar_Precios_Por_Marca
    @ID_Marca              INT,
    @Porcentaje_Incremento DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Validaciones previas
    IF NOT EXISTS (SELECT 1 FROM Prod.Marcas WHERE ID_Marca = @ID_Marca)
    BEGIN
        PRINT 'Error: La marca especificada no existe.';
        RETURN;
    END
 
    IF @Porcentaje_Incremento <= 0
    BEGIN
        PRINT 'Error: El porcentaje de incremento debe ser mayor a cero.';
        RETURN;
    END
 
    BEGIN TRY
        BEGIN TRANSACTION;
 
        DECLARE @Filas_Afectadas INT;
 
        -- Actualiza Precio_Unitario en Transacciones para todos los
        -- productos de la marca indicada
        UPDATE t
        SET t.Precio_Unitario = ROUND(
                t.Precio_Unitario * (1 + @Porcentaje_Incremento / 100), 2)
        FROM Prod.Transacciones t
        INNER JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
        WHERE p.ID_Marca = @ID_Marca;
 
        SET @Filas_Afectadas = @@ROWCOUNT;
 
        COMMIT;
 
        -- Resumen de la operación
        SELECT
            mk.Nombre                  AS Marca,
            @Porcentaje_Incremento     AS Incremento_Aplicado_Pct,
            @Filas_Afectadas           AS Transacciones_Actualizadas
        FROM Prod.Marcas mk
        WHERE mk.ID_Marca = @ID_Marca;
 
        PRINT 'Precios actualizados correctamente.';
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
 
        SELECT
            ERROR_NUMBER()   AS Numero_Error,
            ERROR_LINE()     AS Linea,
            ERROR_MESSAGE()  AS Mensaje;
    END CATCH;
END;
GO
 
-- Prueba: incremento del 10% para la marca con ID 1 (Conexión TI)
EXEC Prod.sp_Actualizar_Precios_Por_Marca
    @ID_Marca              = 1,
    @Porcentaje_Incremento = 10;
GO
 
-- ============================================================
--  SP 2 — Reporte de Rendimiento de Mercado
--  Parámetro: @ID_Mercado
--  Lógica:    Devuelve un resumen del mercado: total vendido,
--             cantidad de facturas y vendedor estrella
--             (el que más ingreso generó en ese mercado).
-- ============================================================
 
CREATE OR ALTER PROCEDURE Prod.sp_Reporte_Rendimiento_Mercado
    @ID_Mercado INT
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Validación
    IF NOT EXISTS (SELECT 1 FROM Prod.Mercados WHERE ID_Region = @ID_Mercado)
    BEGIN
        PRINT 'Error: El mercado especificado no existe.';
        RETURN;
    END
 
    -- Resumen general del mercado
    SELECT
        m.Nombre                                               AS Mercado,
        COUNT(DISTINCT f.ID_Factura)                          AS Total_Facturas,
        COUNT(DISTINCT f.ID_Cliente)                          AS Clientes_Unicos,
        ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)        AS Total_Vendido,
        ROUND(
            SUM(t.Precio_Unitario * t.Cantidad)
          - SUM(t.Costo_Unitario  * t.Cantidad)
        , 2)                                                   AS Utilidad_Bruta
    FROM Prod.Mercados m
    INNER JOIN Prod.Facturas      f ON f.ID_Region  = m.ID_Region
    INNER JOIN Prod.Transacciones t ON t.ID_Factura = f.ID_Factura
    WHERE m.ID_Region = @ID_Mercado
    GROUP BY m.ID_Region, m.Nombre;
 
    -- Vendedor estrella del mercado
    SELECT TOP 1
        v.Nombre_Vendedor                                      AS Vendedor_Estrella,
        COUNT(DISTINCT f.ID_Factura)                          AS Facturas_Gestionadas,
        ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)        AS Total_Vendido
    FROM Prod.Vendedores v
    INNER JOIN Prod.Facturas      f ON f.ID_Vendedor = v.ID_Vendedor
    INNER JOIN Prod.Transacciones t ON t.ID_Factura  = f.ID_Factura
    WHERE f.ID_Region = @ID_Mercado
    GROUP BY v.ID_Vendedor, v.Nombre_Vendedor
    ORDER BY Total_Vendido DESC;
END;
GO
 
-- Prueba: reporte del mercado 1
EXEC Prod.sp_Reporte_Rendimiento_Mercado @ID_Mercado = 1;
GO
 
-- Prueba: reporte del mercado 2
EXEC Prod.sp_Reporte_Rendimiento_Mercado @ID_Mercado = 2;
GO
 
-- ============================================================
--  SP 3 — Baja de Producto con Validación
--  Parámetro: @ID_Producto
--  Lógica:    Intenta eliminar el producto. Si tiene
--             transacciones históricas, bloquea la eliminación
--             y devuelve un mensaje explicativo.
--             Usa transacción para garantizar consistencia.
-- ============================================================
 
CREATE OR ALTER PROCEDURE Prod.sp_Baja_Producto_Con_Validacion
    @ID_Producto INT
AS
BEGIN
    SET NOCOUNT ON;
 
    -- Validación: el producto existe?
    IF NOT EXISTS (SELECT 1 FROM Prod.Productos WHERE ID_Producto = @ID_Producto)
    BEGIN
        PRINT 'Error: El producto especificado no existe en el catálogo.';
        RETURN;
    END
 
    -- Validación: tiene historial de ventas?
    IF EXISTS (SELECT 1 FROM Prod.Transacciones WHERE ID_Producto = @ID_Producto)
    BEGIN
        -- Muestra detalle del historial antes de bloquear
        SELECT
            p.ID_Producto,
            p.Nombre                                           AS Producto,
            COUNT(t.ID_Transaccion)                           AS Transacciones_Historicas,
            ROUND(SUM(t.Precio_Unitario * t.Cantidad), 2)    AS Total_Vendido
        FROM Prod.Productos p
        INNER JOIN Prod.Transacciones t ON t.ID_Producto = p.ID_Producto
        WHERE p.ID_Producto = @ID_Producto
        GROUP BY p.ID_Producto, p.Nombre;
 
        PRINT 'No se puede eliminar: Producto con historial de ventas.';
        RETURN;
    END
 
    -- Si no tiene historial, procede con la eliminación
    BEGIN TRY
        BEGIN TRANSACTION;
 
        DECLARE @Nombre_Producto VARCHAR(255);
        SELECT @Nombre_Producto = Nombre
        FROM Prod.Productos
        WHERE ID_Producto = @ID_Producto;
 
        DELETE FROM Prod.Productos
        WHERE ID_Producto = @ID_Producto;
 
        COMMIT;
 
        PRINT 'Producto eliminado correctamente: ' + @Nombre_Producto;
 
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
 
        SELECT
            ERROR_NUMBER()   AS Numero_Error,
            ERROR_LINE()     AS Linea,
            ERROR_MESSAGE()  AS Mensaje;
    END CATCH;
END;
GO
 
-- Prueba 1: producto CON historial (debe bloquear la eliminación)
EXEC Prod.sp_Baja_Producto_Con_Validacion @ID_Producto = 428;
GO
 
-- Prueba 2: producto SIN historial (debe eliminarse)
-- Primero insertamos un producto de prueba sin transacciones
INSERT INTO Prod.Productos (ID_Producto, Nombre, ID_Marca, Stock)
VALUES (9999, 'Producto de Prueba - Para Eliminar', 1, 0);
 
EXEC Prod.sp_Baja_Producto_Con_Validacion @ID_Producto = 9999;
GO
 
-- ============================================================
--  VERIFICACIÓN FINAL — SPs creados en schema Prod
-- ============================================================
SELECT
    ROUTINE_SCHEMA + '.' + ROUTINE_NAME  AS Procedimiento,
    ROUTINE_TYPE                          AS Tipo
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'Prod'
  AND ROUTINE_TYPE   = 'PROCEDURE'
ORDER BY ROUTINE_NAME;
GO
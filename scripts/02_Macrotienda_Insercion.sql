-- ============================================================
--  SCRIPT 02 — INSERCIÓN DE DATOS (ETL)
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Fuentes:  Ventas.csv  |  Productos.csv
-- ============================================================
--
--  FLUJO ETL:
--    FASE 1 — Staging:       carga cruda desde CSVs a tablas temporales
--    FASE 2 — Transformación: limpieza, conversión de tipos, normalización
--    FASE 3 — Carga:         inserción en tablas definitivas (orden Star Schema)
--    FASE 4 — Validación:    checks de integridad y conteos finales
--
--  NOTAS SOBRE EL CSV:
--    - Separador de campo:    ;
--    - Separador decimal:     , (coma)  →  se reemplaza por punto al castear
--    - Fechas:                yyyy-mm-dd  →  TRY_CAST directo a DATE
--    - Mercado "Brazil":      se normaliza a "Brasil" en la carga
--    - Fila vacía al final:   se elimina antes de procesar
--    - Encoding:              ACP (Latin-1 / Windows-1252)
-- ============================================================

USE Macrotienda;
GO

SET NOCOUNT ON;
GO

BEGIN TRY
    BEGIN TRAN;

    -- --------------------------------------------------------
    --  FASE 1 — STAGING
    --  Tablas temporales con todo como VARCHAR.
    --  Los tipos se resuelven en la Fase 2.
    -- --------------------------------------------------------

    -- Limpieza previa por si el script se re-ejecuta en la misma sesión
    IF OBJECT_ID('tempdb..#VentasTemp')   IS NOT NULL DROP TABLE #VentasTemp;
    IF OBJECT_ID('tempdb..#ProductosTemp') IS NOT NULL DROP TABLE #ProductosTemp;

    -- Tabla temporal: Ventas
    CREATE TABLE #VentasTemp (
        ID_Transaccion   VARCHAR(255) NOT NULL,
        ID_Factura       VARCHAR(255) NOT NULL,
        Fecha_Venta      VARCHAR(255) NOT NULL,
        Fecha_Envio      VARCHAR(255) NOT NULL,
        ID_Producto      VARCHAR(255) NOT NULL,
        Nombre_Producto  VARCHAR(255) NOT NULL,
        Marca            VARCHAR(255) NOT NULL,
        Centro_Logistico VARCHAR(255) NOT NULL,
        Latitud          VARCHAR(255) NOT NULL,
        Longitud         VARCHAR(255) NOT NULL,
        ID_Vendedor      VARCHAR(255) NOT NULL,
        Nombre_Vendedor  VARCHAR(255) NOT NULL,
        Apellido_Vendedor VARCHAR(255) NOT NULL,
        Fecha_Nacimiento VARCHAR(255) NOT NULL,
        Mercado          VARCHAR(255) NOT NULL,
        ID_Cliente       VARCHAR(255) NOT NULL,
        Nombre_Cliente   VARCHAR(255) NOT NULL,
        Pais_Cliente     VARCHAR(255) NOT NULL,
        Cantidad         VARCHAR(255) NOT NULL,
        Precio_Unitario  VARCHAR(255) NOT NULL,
        Costo_Unitario   VARCHAR(255) NOT NULL
    );

    -- Tabla temporal: Productos (para cargar stock real)
    CREATE TABLE #ProductosTemp (
        ID_Producto  VARCHAR(255) NOT NULL,
        Nombre       VARCHAR(255) NOT NULL,
        ID_Marca     VARCHAR(255) NOT NULL,
        Stock        VARCHAR(255) NOT NULL
    );

    -- --------------------------------------------------------
    --  BULK INSERT
    --  Ajustá las rutas según tu equipo.
    -- --------------------------------------------------------

    BULK INSERT #VentasTemp
    FROM 'C:\Users\mlope\OneDrive\Escritorio\SQL360\Tarea\Ventas.csv'
    WITH (
        FIRSTROW       = 2,
        FIELDTERMINATOR = ';',
        ROWTERMINATOR  = '0x0D0A',
        CODEPAGE       = 'ACP',
        TABLOCK
    );

    BULK INSERT #ProductosTemp
    FROM 'C:\Users\mlope\OneDrive\Escritorio\SQL360\Tarea\Productos.csv'
    WITH (
        FIRSTROW       = 1,          -- Productos.csv no tiene encabezado
        FIELDTERMINATOR = ';',
        ROWTERMINATOR  = '0x0D0A',
        CODEPAGE       = '65001',    -- UTF-8
        TABLOCK
    );

    -- --------------------------------------------------------
    --  FASE 2 — TRANSFORMACIÓN
    --  Materializamos los datos limpios en #Limpia.
    --  Usamos tabla temporal (no CTE) para poder reutilizarla
    --  en todos los INSERT de la Fase 3.
    -- --------------------------------------------------------

    IF OBJECT_ID('tempdb..#Limpia') IS NOT NULL DROP TABLE #Limpia;

    SELECT
        -- IDs
        TRY_CAST(NULLIF(TRIM(ID_Transaccion),  '') AS INT)  AS ID_Transaccion,
        TRY_CAST(NULLIF(TRIM(ID_Factura),       '') AS INT)  AS ID_Factura,
        TRY_CAST(NULLIF(TRIM(ID_Producto),      '') AS INT)  AS ID_Producto,
        TRY_CAST(NULLIF(TRIM(ID_Vendedor),      '') AS INT)  AS ID_Vendedor,
        TRY_CAST(NULLIF(TRIM(ID_Cliente),       '') AS INT)  AS ID_Cliente,

        -- Fechas (yyyy-mm-dd → cast directo)
        TRY_CAST(NULLIF(TRIM(Fecha_Venta),      '') AS DATE) AS Fecha_Venta,
        TRY_CAST(NULLIF(TRIM(Fecha_Envio),      '') AS DATE) AS Fecha_Envio,
        TRY_CAST(NULLIF(TRIM(Fecha_Nacimiento), '') AS DATE) AS Fecha_Nacimiento,

        -- Textos normalizados
        TRIM(Nombre_Producto)                                AS Nombre_Producto,
        TRIM(Marca)                                          AS Marca,
        TRIM(Centro_Logistico)                               AS Centro_Logistico,
        TRIM(Nombre_Cliente)                                 AS Nombre_Cliente,
        TRIM(Pais_Cliente)                                   AS Pais_Cliente,
        TRIM(Nombre_Vendedor) + ' ' + TRIM(Apellido_Vendedor) AS Nombre_Vendedor,

        -- Mercado: normalizamos "Brazil" → "Brasil"
        CASE WHEN TRIM(Mercado) = 'Brazil' THEN 'Brasil'
             ELSE TRIM(Mercado)
        END AS Mercado,

        -- Numéricos: reemplazamos coma decimal por punto
        TRY_CAST(NULLIF(TRIM(Cantidad), '') AS INT)          AS Cantidad,

        TRY_CAST(
            NULLIF(REPLACE(TRIM(Precio_Unitario), ',', '.'), '')
        AS DECIMAL(18,2))                                    AS Precio_Unitario,

        TRY_CAST(
            NULLIF(REPLACE(TRIM(Costo_Unitario), ',', '.'), '')
        AS DECIMAL(18,2))                                    AS Costo_Unitario,

        TRY_CAST(
            NULLIF(REPLACE(TRIM(Latitud), ',', '.'), '')
        AS DECIMAL(9,5))                                     AS Latitud,

        TRY_CAST(
            NULLIF(REPLACE(TRIM(Longitud), ',', '.'), '')
        AS DECIMAL(9,5))                                     AS Longitud

    INTO #Limpia
    FROM #VentasTemp
    WHERE NULLIF(TRIM(ID_Transaccion), '') IS NOT NULL;  -- elimina fila vacía

    -- --------------------------------------------------------
    --  FASE 3 — CARGA EN TABLAS DEFINITIVAS
    --  Orden Star Schema: primero dimensiones, luego hechos.
    --  NOT EXISTS evita duplicados si el script se re-ejecuta.
    -- --------------------------------------------------------

    -- 1) MERCADOS
    INSERT INTO Prod.Mercados (Nombre)
    SELECT DISTINCT l.Mercado
    FROM #Limpia l
    WHERE NULLIF(l.Mercado, '') IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Mercados m WHERE m.Nombre = l.Mercado
      );

    -- 2) CLIENTES
    INSERT INTO Prod.Clientes (ID_Cliente, Nombre, Pais_Cliente)
    SELECT DISTINCT l.ID_Cliente, l.Nombre_Cliente, l.Pais_Cliente
    FROM #Limpia l
    WHERE l.ID_Cliente IS NOT NULL
      AND NULLIF(l.Nombre_Cliente, '') IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Clientes c WHERE c.ID_Cliente = l.ID_Cliente
      );

    -- 3) MARCAS
    --    Se insertan en orden alfabético para que el IDENTITY genere
    --    los IDs 1-5 que ya usa Productos.csv.
    INSERT INTO Prod.Marcas (Nombre, Centro_Logistico, Latitud, Longitud)
    SELECT DISTINCT l.Marca, l.Centro_Logistico, l.Latitud, l.Longitud
    FROM #Limpia l
    WHERE NULLIF(l.Marca, '') IS NOT NULL
      AND l.Latitud  IS NOT NULL
      AND l.Longitud IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Marcas mk WHERE mk.Nombre = l.Marca
      )
    ORDER BY l.Marca;   -- orden alfabético = IDs 1 a 5 correctos

    -- 4) PRODUCTOS
    --    Cargamos desde #ProductosTemp (tiene stock real y ID_Marca directo).
    INSERT INTO Prod.Productos (ID_Producto, Nombre, ID_Marca, Stock)
    SELECT
        TRY_CAST(NULLIF(TRIM(pt.ID_Producto), '') AS INT),
        TRIM(pt.Nombre),
        TRY_CAST(NULLIF(TRIM(pt.ID_Marca), '')    AS INT),
        TRY_CAST(NULLIF(TRIM(pt.Stock), '')        AS INT)
    FROM #ProductosTemp pt
    WHERE TRY_CAST(NULLIF(TRIM(pt.ID_Producto), '') AS INT) IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Productos p
          WHERE p.ID_Producto = TRY_CAST(NULLIF(TRIM(pt.ID_Producto), '') AS INT)
      );

    -- 5) VENDEDORES
    INSERT INTO Prod.Vendedores (ID_Vendedor, Nombre_Vendedor, Fecha_Nacimiento, ID_Sucursal)
    SELECT DISTINCT
        l.ID_Vendedor,
        l.Nombre_Vendedor,
        l.Fecha_Nacimiento,
        m.ID_Region
    FROM #Limpia l
    INNER JOIN Prod.Mercados m ON m.Nombre = l.Mercado
    WHERE l.ID_Vendedor     IS NOT NULL
      AND NULLIF(l.Nombre_Vendedor, '') IS NOT NULL
      AND l.Fecha_Nacimiento IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Vendedores v WHERE v.ID_Vendedor = l.ID_Vendedor
      );

    -- 6) FACTURAS
    INSERT INTO Prod.Facturas (ID_Factura, Fecha_Venta, ID_Vendedor, ID_Cliente, ID_Region)
    SELECT DISTINCT
        l.ID_Factura,
        l.Fecha_Venta,
        l.ID_Vendedor,
        l.ID_Cliente,
        m.ID_Region
    FROM #Limpia l
    INNER JOIN Prod.Mercados m ON m.Nombre = l.Mercado
    WHERE l.ID_Factura  IS NOT NULL
      AND l.Fecha_Venta IS NOT NULL
      AND l.ID_Vendedor IS NOT NULL
      AND l.ID_Cliente  IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Facturas f WHERE f.ID_Factura = l.ID_Factura
      );

    -- 7) TRANSACCIONES (tabla de hechos)
    INSERT INTO Prod.Transacciones (
        ID_Transaccion,
        Fecha_Envio,
        ID_Factura,
        ID_Producto,
        Cantidad,
        Precio_Unitario,
        Costo_Unitario
    )
    SELECT DISTINCT
        l.ID_Transaccion,
        l.Fecha_Envio,
        l.ID_Factura,
        l.ID_Producto,
        l.Cantidad,
        l.Precio_Unitario,
        l.Costo_Unitario
    FROM #Limpia l
    WHERE l.ID_Transaccion  IS NOT NULL
      AND l.Fecha_Envio     IS NOT NULL
      AND l.ID_Factura      IS NOT NULL
      AND l.ID_Producto     IS NOT NULL
      AND l.Cantidad        IS NOT NULL
      AND l.Precio_Unitario IS NOT NULL
      AND l.Costo_Unitario  IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM Prod.Transacciones t
          WHERE t.ID_Transaccion = l.ID_Transaccion
      );

    -- --------------------------------------------------------
    --  FASE 4 — VALIDACIÓN DE INTEGRIDAD
    -- --------------------------------------------------------

    -- Transacciones sin factura válida (debe ser 0)
    IF EXISTS (
        SELECT 1
        FROM Prod.Transacciones t
        LEFT JOIN Prod.Facturas f ON f.ID_Factura = t.ID_Factura
        WHERE f.ID_Factura IS NULL
    )
        THROW 50001, 'Error: existen transacciones sin factura válida.', 1;

    -- Transacciones sin producto válido (debe ser 0)
    IF EXISTS (
        SELECT 1
        FROM Prod.Transacciones t
        LEFT JOIN Prod.Productos p ON p.ID_Producto = t.ID_Producto
        WHERE p.ID_Producto IS NULL
    )
        THROW 50002, 'Error: existen transacciones sin producto válido.', 1;

    -- Nulos en campos NOT NULL de Transacciones (debe ser 0)
    IF EXISTS (
        SELECT 1
        FROM Prod.Transacciones
        WHERE Precio_Unitario IS NULL
           OR Costo_Unitario  IS NULL
           OR Cantidad        IS NULL
           OR Fecha_Envio     IS NULL
    )
        THROW 50003, 'Error: existen NULLs en campos obligatorios de Transacciones.', 1;

    COMMIT;

    -- --------------------------------------------------------
    --  RESUMEN FINAL DE CARGA
    -- --------------------------------------------------------
    SELECT 'Mercados'      AS Tabla, COUNT(*) AS Filas_Cargadas FROM Prod.Mercados
    UNION ALL
    SELECT 'Clientes',              COUNT(*)                    FROM Prod.Clientes
    UNION ALL
    SELECT 'Marcas',                COUNT(*)                    FROM Prod.Marcas
    UNION ALL
    SELECT 'Productos',             COUNT(*)                    FROM Prod.Productos
    UNION ALL
    SELECT 'Vendedores',            COUNT(*)                    FROM Prod.Vendedores
    UNION ALL
    SELECT 'Facturas',              COUNT(*)                    FROM Prod.Facturas
    UNION ALL
    SELECT 'Transacciones',         COUNT(*)                    FROM Prod.Transacciones;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;

    SELECT
        ERROR_NUMBER()   AS Numero_Error,
        ERROR_SEVERITY() AS Severidad,
        ERROR_STATE()    AS Estado,
        ERROR_LINE()     AS Linea,
        ERROR_MESSAGE()  AS Mensaje;
END CATCH;
GO

-- --------------------------------------------------------
--  VERIFICACIÓN RÁPIDA — una fila por tabla
-- --------------------------------------------------------
SELECT TOP 1 * FROM Prod.Mercados;
SELECT TOP 1 * FROM Prod.Clientes;
SELECT TOP 1 * FROM Prod.Marcas;
SELECT TOP 1 * FROM Prod.Productos;
SELECT TOP 1 * FROM Prod.Vendedores;
SELECT TOP 1 * FROM Prod.Facturas;
SELECT TOP 1 * FROM Prod.Transacciones;
GO
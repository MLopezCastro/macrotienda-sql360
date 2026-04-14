-- ============================================================
--  SCRIPT 07 — TRIGGERS
--  Proyecto: Macrotienda
--  Autor:    Marcelo López
--  Consigna: 7 — Implementación de Triggers de Auditoría
-- ============================================================
--
--  Contenido:
--    0. Creación de tabla Prod.Auditoria
--    1. Trigger de Auditoría de Eliminación (AFTER DELETE)
--    2. Trigger de Bloqueo por Stock (INSTEAD OF DELETE)
--    3. Pruebas de ambos triggers
-- ============================================================

USE Macrotienda;
GO

-- ============================================================
--  0. TABLA DE AUDITORÍA
--  Registra cada intento de eliminación sobre Prod.Productos:
--  qué producto, cuándo, quién y qué pasó.
-- ============================================================

CREATE TABLE Prod.Auditoria (
    ID_Auditoria  INT           NOT NULL IDENTITY PRIMARY KEY,
    Fecha_Hora    DATETIME      NOT NULL DEFAULT GETDATE(),
    Tabla         VARCHAR(100)  NOT NULL,
    Operacion     VARCHAR(50)   NOT NULL,
    ID_Producto   INT           NOT NULL,
    Nombre        VARCHAR(255)  NOT NULL,
    ID_Marca      INT               NULL,
    Stock         INT               NULL,
    Usuario       VARCHAR(255)  NOT NULL,
    Estado        VARCHAR(50)   NOT NULL,
    Observacion   VARCHAR(500)      NULL
);
GO

-- ============================================================
--  TRIGGER 1 — Auditoría de Eliminación
--  Evento:  AFTER DELETE sobre Prod.Productos
--  Lógica:  Cada vez que se elimina un producto, el trigger
--           captura los datos del registro eliminado (desde
--           la tabla virtual 'deleted') e inserta un log
--           en Prod.Auditoria con fecha, usuario y detalle.
-- ============================================================

CREATE OR ALTER TRIGGER Prod.trg_Auditoria_Eliminacion_Producto
ON Prod.Productos
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Prod.Auditoria
    (
        Tabla,
        Operacion,
        ID_Producto,
        Nombre,
        ID_Marca,
        Stock,
        Usuario,
        Estado,
        Observacion
    )
    SELECT
        'Prod.Productos',
        'DELETE',
        d.ID_Producto,
        d.Nombre,
        d.ID_Marca,
        d.Stock,
        SYSTEM_USER,        -- usuario de SQL Server que ejecutó la operación
        'Eliminado',
        'Registro eliminado de Prod.Productos'
    FROM deleted d;         -- tabla virtual con los datos eliminados
END;
GO

-- ============================================================
--  TRIGGER 2 — Bloqueo de Eliminación por Stock (Opcional)
--  Evento:  INSTEAD OF DELETE sobre Prod.Productos
--  Lógica:  Antes de ejecutar el DELETE, verifica si el
--           producto tiene Stock > 0. Si es así, cancela
--           la operación y registra el intento en Auditoria.
--           Si Stock = 0 o NULL, permite la eliminación
--           y deja que el Trigger 1 registre la auditoría.
-- ============================================================

CREATE OR ALTER TRIGGER Prod.trg_Bloqueo_Eliminacion_Por_Stock
ON Prod.Productos
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Productos bloqueados (tienen stock > 0)
    IF EXISTS (SELECT 1 FROM deleted WHERE Stock > 0)
    BEGIN
        -- Registra el intento bloqueado en Auditoria
        INSERT INTO Prod.Auditoria
        (
            Tabla, Operacion, ID_Producto, Nombre,
            ID_Marca, Stock, Usuario, Estado, Observacion
        )
        SELECT
            'Prod.Productos',
            'DELETE - BLOQUEADO',
            d.ID_Producto,
            d.Nombre,
            d.ID_Marca,
            d.Stock,
            SYSTEM_USER,
            'Bloqueado',
            'No se puede eliminar: el producto tiene stock disponible (' 
                + CAST(d.Stock AS VARCHAR) + ' unidades).'
        FROM deleted d
        WHERE d.Stock > 0;

        -- Lanza error para que el usuario vea el mensaje
        RAISERROR('No se puede eliminar: el producto tiene stock disponible.', 16, 1);
        RETURN;
    END

    -- Si stock = 0 o NULL, procede con la eliminación real
    -- (el Trigger 1 AFTER DELETE registrará la auditoría)
    DELETE FROM Prod.Productos
    WHERE ID_Producto IN (SELECT ID_Producto FROM deleted);
END;
GO

-- ============================================================
--  PRUEBAS
-- ============================================================

-- Insertamos dos productos de prueba sin historial de ventas:
-- uno con stock y otro sin stock
INSERT INTO Prod.Productos (ID_Producto, Nombre, ID_Marca, Stock)
VALUES (9001, 'Producto Prueba - Con Stock',    1, 150);

INSERT INTO Prod.Productos (ID_Producto, Nombre, ID_Marca, Stock)
VALUES (9002, 'Producto Prueba - Sin Stock',    1, 0);
GO

-- Verificamos que se insertaron
SELECT * FROM Prod.Productos WHERE ID_Producto IN (9001, 9002);
GO

-- PRUEBA 1: Intentar eliminar producto CON stock
-- Debe ser bloqueado por el Trigger 2 y registrado en Auditoría
DELETE FROM Prod.Productos WHERE ID_Producto = 9001;
GO

-- PRUEBA 2: Eliminar producto SIN stock
-- Debe eliminarse correctamente y registrarse en Auditoría
DELETE FROM Prod.Productos WHERE ID_Producto = 9002;
GO

-- Verificamos la tabla de Auditoría — deben aparecer ambos intentos
SELECT
    ID_Auditoria,
    Fecha_Hora,
    Operacion,
    ID_Producto,
    Nombre,
    Stock,
    Usuario,
    Estado,
    Observacion
FROM Prod.Auditoria
ORDER BY ID_Auditoria;
GO

-- ============================================================
--  VERIFICACIÓN FINAL — Triggers creados en schema Prod
-- ============================================================
SELECT
    t.name                                    AS Trigger_Nombre,
    OBJECT_NAME(t.parent_id)                  AS Tabla,
    te.type_desc                              AS Evento
FROM sys.triggers t
INNER JOIN sys.trigger_events te ON te.object_id = t.object_id
WHERE SCHEMA_NAME(
    OBJECTPROPERTY(t.parent_id, 'SchemaId')) = 'Prod'
ORDER BY Trigger_Nombre;
GO

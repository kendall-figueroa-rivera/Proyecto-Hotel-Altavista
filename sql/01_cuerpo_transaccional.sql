-- =============================================
-- HOTEL LENGUAJE - CUERPO TRANSACCIONAL
-- Funciones, Procedimientos Almacenados y Triggers
-- =============================================
USE hotelLenguaje;
GO

-- =============================================
-- FUNCIONES
-- =============================================

-- F1: Calcular total de reservacion con descuento de oferta
CREATE OR ALTER FUNCTION fn_CalcularTotalReservacion(
    @idHabitacion INT,
    @fechaEntrada DATE,
    @fechaSalida  DATE,
    @idOferta     INT
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @precioNoche DECIMAL(10,2)
    DECLARE @noches      INT
    DECLARE @descuento   DECIMAL(5,2)
    DECLARE @total       DECIMAL(10,2)

    SELECT @precioNoche = precio_noche
    FROM habitaciones WHERE id_habitacion = @idHabitacion

    SET @noches = DATEDIFF(DAY, @fechaEntrada, @fechaSalida)
    SET @descuento = 0

    IF @idOferta IS NOT NULL
        SELECT @descuento = descuento FROM ofertas
        WHERE id_oferta = @idOferta
          AND GETDATE() BETWEEN fecha_inicio AND fecha_fin

    SET @total = (@precioNoche * @noches) * (1 - @descuento / 100)
    RETURN ISNULL(@total, 0)
END
GO

-- F2: Verificar disponibilidad de habitacion
CREATE OR ALTER FUNCTION fn_HabitacionDisponible(
    @idHabitacion INT,
    @fechaEntrada DATE,
    @fechaSalida  DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @conflictos INT
    SELECT @conflictos = COUNT(*)
    FROM reservaciones
    WHERE id_habitacion = @idHabitacion
      AND estado NOT IN ('cancelada')
      AND fecha_entrada < @fechaSalida
      AND fecha_salida  > @fechaEntrada

    IF @conflictos > 0 RETURN 0
    RETURN 1
END
GO

-- F3: Total de ingresos en rango de fechas
CREATE OR ALTER FUNCTION fn_TotalIngresosPorFecha(
    @fechaInicio DATE,
    @fechaFin    DATE
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @total DECIMAL(10,2)
    SELECT @total = ISNULL(SUM(monto), 0)
    FROM pagos
    WHERE estado = 'completado'
      AND CAST(fecha_pago AS DATE) BETWEEN @fechaInicio AND @fechaFin
    RETURN @total
END
GO

-- =============================================
-- PROCEDIMIENTOS ALMACENADOS
-- =============================================

-- SP1: Crear reservacion (proceso principal)
CREATE OR ALTER PROCEDURE sp_CrearReservacion
    @idUsuario    INT,
    @idHabitacion INT,
    @fechaEntrada DATE,
    @fechaSalida  DATE,
    @idOferta     INT = NULL,
    @mensaje      VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION
    BEGIN TRY
        IF @fechaEntrada >= @fechaSalida
        BEGIN
            SET @mensaje = 'ERROR: Fecha entrada debe ser anterior a fecha salida'
            ROLLBACK TRANSACTION RETURN
        END

        IF @fechaEntrada < CAST(GETDATE() AS DATE)
        BEGIN
            SET @mensaje = 'ERROR: La fecha de entrada no puede ser en el pasado'
            ROLLBACK TRANSACTION RETURN
        END

        IF dbo.fn_HabitacionDisponible(@idHabitacion, @fechaEntrada, @fechaSalida) = 0
        BEGIN
            SET @mensaje = 'ERROR: Habitacion no disponible en esas fechas'
            ROLLBACK TRANSACTION RETURN
        END

        DECLARE @total DECIMAL(10,2)
        SET @total = dbo.fn_CalcularTotalReservacion(@idHabitacion, @fechaEntrada, @fechaSalida, @idOferta)

        INSERT INTO reservaciones (fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion, id_oferta)
        VALUES (@fechaEntrada, @fechaSalida, 'confirmada', @total, @idUsuario, @idHabitacion, @idOferta)

        SET @mensaje = 'OK: Reservacion creada. Total: ' + CAST(@total AS VARCHAR(20))
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- SP2: Procesar pago y generar factura
CREATE OR ALTER PROCEDURE sp_ProcesarPago
    @idReservacion INT,
    @idMetodoPago  INT,
    @monto         DECIMAL(10,2),
    @mensaje       VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION
    BEGIN TRY
        DECLARE @estadoRes VARCHAR(50)
        SELECT @estadoRes = estado FROM reservaciones
        WHERE id_reservacion = @idReservacion

        IF @estadoRes IS NULL
        BEGIN SET @mensaje = 'ERROR: Reservacion no existe' ROLLBACK TRANSACTION RETURN END

        IF @estadoRes = 'cancelada'
        BEGIN SET @mensaje = 'ERROR: No se puede pagar reservacion cancelada' ROLLBACK TRANSACTION RETURN END

        IF @monto <= 0
        BEGIN SET @mensaje = 'ERROR: Monto debe ser mayor a cero' ROLLBACK TRANSACTION RETURN END

        DECLARE @idPago INT
        INSERT INTO pagos (fecha_pago, monto, estado, id_reservacion, id_metodo_pago)
        VALUES (GETDATE(), @monto, 'completado', @idReservacion, @idMetodoPago)
        SET @idPago = SCOPE_IDENTITY()

        DECLARE @impuesto DECIMAL(10,2) = ROUND(@monto * 0.13, 2)
        DECLARE @subtotal DECIMAL(10,2) = ROUND(@monto - @impuesto, 2)

        INSERT INTO facturas (fecha_emision, subtotal, impuesto, total, id_pago)
        VALUES (GETDATE(), @subtotal, @impuesto, @monto, @idPago)

        SET @mensaje = 'OK: Pago procesado y factura generada. ID Pago: ' + CAST(@idPago AS VARCHAR(10))
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- SP3: Cancelar reservacion con reembolso opcional
CREATE OR ALTER PROCEDURE sp_CancelarReservacion
    @idReservacion    INT,
    @motivo           VARCHAR(255),
    @aplicarReembolso BIT = 0,
    @mensaje          VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION
    BEGIN TRY
        DECLARE @estadoRes VARCHAR(50)
        SELECT @estadoRes = estado FROM reservaciones
        WHERE id_reservacion = @idReservacion

        IF @estadoRes IS NULL
        BEGIN SET @mensaje = 'ERROR: Reservacion no encontrada' ROLLBACK TRANSACTION RETURN END

        IF @estadoRes = 'cancelada'
        BEGIN SET @mensaje = 'ERROR: La reservacion ya esta cancelada' ROLLBACK TRANSACTION RETURN END

        UPDATE reservaciones SET estado = 'cancelada'
        WHERE id_reservacion = @idReservacion

        IF @aplicarReembolso = 1
        BEGIN
            DECLARE @idPago INT
            DECLARE @montoPago DECIMAL(10,2)
            SELECT TOP 1 @idPago = id_pago, @montoPago = monto
            FROM pagos
            WHERE id_reservacion = @idReservacion AND estado = 'completado'
            ORDER BY fecha_pago DESC

            IF @idPago IS NOT NULL
            BEGIN
                INSERT INTO reembolsos (fecha_reembolso, monto, motivo, id_pago)
                VALUES (GETDATE(), @montoPago, @motivo, @idPago)
                UPDATE pagos SET estado = 'reembolsado' WHERE id_pago = @idPago
            END
        END

        SET @mensaje = 'OK: Reservacion cancelada exitosamente'
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- SP4: Registrar venta de producto con control de stock
CREATE OR ALTER PROCEDURE sp_RegistrarVenta
    @idUsuario  INT,
    @idProducto INT,
    @cantidad   INT,
    @mensaje    VARCHAR(255) OUTPUT
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRANSACTION
    BEGIN TRY
        DECLARE @stockActual    INT
        DECLARE @precioProducto DECIMAL(10,2)

        SELECT @stockActual = stock, @precioProducto = precio
        FROM productos WHERE id_producto = @idProducto

        IF @stockActual IS NULL
        BEGIN SET @mensaje = 'ERROR: Producto no encontrado' ROLLBACK TRANSACTION RETURN END

        IF @stockActual < @cantidad
        BEGIN
            SET @mensaje = 'ERROR: Stock insuficiente. Disponible: ' + CAST(@stockActual AS VARCHAR(10))
            ROLLBACK TRANSACTION RETURN
        END

        DECLARE @subtotal DECIMAL(10,2) = @precioProducto * @cantidad

        DECLARE @idVenta INT
        INSERT INTO ventas (fecha_venta, total, id_usuario)
        VALUES (GETDATE(), @subtotal, @idUsuario)
        SET @idVenta = SCOPE_IDENTITY()

        INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal)
        VALUES (@idVenta, @idProducto, @cantidad, @subtotal)

        UPDATE productos SET stock = stock - @cantidad
        WHERE id_producto = @idProducto

        SET @mensaje = 'OK: Venta registrada. Total: ₡' + CAST(@subtotal AS VARCHAR(20))
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- =============================================
-- TABLA DE AUDITORIA
-- =============================================
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='auditoria_reservaciones' AND xtype='U')
    CREATE TABLE auditoria_reservaciones (
        id_auditoria    INT IDENTITY(1,1) PRIMARY KEY,
        id_reservacion  INT,
        estado_anterior VARCHAR(50),
        estado_nuevo    VARCHAR(50),
        fecha_cambio    DATETIME DEFAULT GETDATE(),
        usuario_sistema VARCHAR(100) DEFAULT SYSTEM_USER
    );
GO

-- =============================================
-- TRIGGERS
-- =============================================

-- T1: Actualizar estado de habitacion segun reservaciones
CREATE OR ALTER TRIGGER trg_ActualizarEstadoHabitacion
ON reservaciones
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON
    -- Marcar como ocupada
    UPDATE habitaciones SET estado = 'ocupada'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion FROM inserted
        WHERE estado = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )
    -- Marcar como disponible si se cancelo
    UPDATE habitaciones SET estado = 'disponible'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion FROM inserted WHERE estado = 'cancelada'
    )
    AND id_habitacion NOT IN (
        SELECT id_habitacion FROM reservaciones
        WHERE estado = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )
END
GO

-- T2: Auditoria de cambios en estado de reservaciones
CREATE OR ALTER TRIGGER trg_AuditoriaReservaciones
ON reservaciones
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON
    INSERT INTO auditoria_reservaciones (id_reservacion, estado_anterior, estado_nuevo)
    SELECT i.id_reservacion, d.estado, i.estado
    FROM inserted i
    INNER JOIN deleted d ON i.id_reservacion = d.id_reservacion
    WHERE i.estado <> d.estado
END
GO

-- T3: Prevenir stock negativo
CREATE OR ALTER TRIGGER trg_ValidarStock
ON detalle_venta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN productos p ON i.id_producto = p.id_producto
        WHERE p.stock < 0
    )
    BEGIN
        RAISERROR('ERROR: Stock insuficiente', 16, 1)
        ROLLBACK TRANSACTION
    END
END
GO

-- =============================================
-- INSERTAR DATOS DE PRUEBA
-- =============================================
INSERT INTO metodos_pago (nombre) VALUES ('Efectivo'), ('Tarjeta de credito'), ('Transferencia'), ('SINPE Movil');

INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES
(101, 'individual',  45000, 'disponible'),
(102, 'doble',       75000, 'disponible'),
(201, 'suite',      150000, 'disponible'),
(202, 'doble',       75000, 'disponible'),
(301, 'penthouse',  250000, 'disponible');

INSERT INTO productos (nombre, descripcion, precio, stock) VALUES
('Agua mineral',    'Botella 500ml',   1500,  100),
('Cafe',            'Taza de cafe',    2500,   50),
('Snack mixto',     'Bolsa snacks',    3500,   75),
('Vino tinto',      'Copa vino tinto', 8000,   30),
('Servicio lavanderia', 'Por prenda',  5000,  200);

INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin) VALUES
('Temporada baja',    '15% de descuento en temporada baja',  15.00, '2026-01-01', '2026-06-30'),
('Fin de semana',     '10% descuento fines de semana',       10.00, '2026-01-01', '2026-12-31'),
('Estadia larga',     '20% descuento por 7+ noches',         20.00, '2026-01-01', '2026-12-31');

PRINT '======================================'
PRINT 'Cuerpo transaccional creado con exito'
PRINT '======================================'
GO

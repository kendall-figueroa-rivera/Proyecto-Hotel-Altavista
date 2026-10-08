-- =============================================
-- HOTEL LENGUAJE - SCRIPT COMPLETO
-- SC-504 Lenguajes de Base de Datos
-- =============================================
-- Orden de ejecución:
-- 1. Crear base de datos
-- 2. Crear tablas
-- 3. Insertar datos base
-- 4. Crear funciones
-- 5. Crear procedimientos almacenados
-- 6. Crear triggers
-- 7. Insertar datos de prueba
-- =============================================

-- =============================================
-- PASO 1: CREAR BASE DE DATOS
-- =============================================
USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'hotelLenguaje')
    DROP DATABASE hotelLenguaje;
GO

CREATE DATABASE hotelLenguaje;
GO

USE hotelLenguaje;
GO

-- =============================================
-- PASO 2: CREAR TABLAS
-- =============================================

CREATE TABLE roles (
    id_rol      INT PRIMARY KEY IDENTITY(1,1),
    nombre      VARCHAR(50)  NOT NULL,
    descripcion VARCHAR(255)
);

CREATE TABLE usuarios (
    id_usuario     INT PRIMARY KEY IDENTITY(1,1),
    nombre         VARCHAR(100) NOT NULL,
    apellido_1     VARCHAR(100) NOT NULL,
    apellido_2     VARCHAR(100),
    identificacion VARCHAR(50)  NOT NULL UNIQUE,
    correo         VARCHAR(150) NOT NULL UNIQUE,
    telefono       VARCHAR(20),
    username       VARCHAR(50)  NOT NULL UNIQUE,
    contrasena     VARCHAR(255) NOT NULL,
    fecha_registro DATE         NOT NULL,
    id_rol         INT,
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol)
);

CREATE TABLE habitaciones (
    id_habitacion INT PRIMARY KEY IDENTITY(1,1),
    numero        INT            NOT NULL UNIQUE,
    tipo          VARCHAR(50)    NOT NULL,
    precio_noche  DECIMAL(10,2)  NOT NULL,
    estado        VARCHAR(50)    NOT NULL
);

CREATE TABLE ofertas (
    id_oferta   INT PRIMARY KEY IDENTITY(1,1),
    titulo      VARCHAR(100)  NOT NULL,
    descripcion VARCHAR(255),
    descuento   DECIMAL(5,2)  NOT NULL,
    fecha_inicio DATE          NOT NULL,
    fecha_fin    DATE          NOT NULL
);

CREATE TABLE reservaciones (
    id_reservacion INT PRIMARY KEY IDENTITY(1,1),
    fecha_entrada  DATE          NOT NULL,
    fecha_salida   DATE          NOT NULL,
    estado         VARCHAR(50)   NOT NULL,
    total_pago     DECIMAL(10,2),
    id_usuario     INT           NOT NULL,
    id_habitacion  INT           NOT NULL,
    id_oferta      INT,
    FOREIGN KEY (id_usuario)    REFERENCES usuarios(id_usuario),
    FOREIGN KEY (id_habitacion) REFERENCES habitaciones(id_habitacion),
    FOREIGN KEY (id_oferta)     REFERENCES ofertas(id_oferta)
);

CREATE TABLE metodos_pago (
    id_metodo_pago INT PRIMARY KEY IDENTITY(1,1),
    nombre         VARCHAR(50) NOT NULL
);

CREATE TABLE pagos (
    id_pago        INT PRIMARY KEY IDENTITY(1,1),
    fecha_pago     DATETIME      NOT NULL,
    monto          DECIMAL(10,2) NOT NULL,
    estado         VARCHAR(50)   NOT NULL,
    id_reservacion INT           NOT NULL,
    id_metodo_pago INT           NOT NULL,
    FOREIGN KEY (id_reservacion) REFERENCES reservaciones(id_reservacion),
    FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago)
);

CREATE TABLE facturas (
    id_factura    INT PRIMARY KEY IDENTITY(1,1),
    fecha_emision DATETIME      NOT NULL,
    subtotal      DECIMAL(10,2) NOT NULL,
    impuesto      DECIMAL(10,2) NOT NULL,
    total         DECIMAL(10,2) NOT NULL,
    id_pago       INT           NOT NULL,
    FOREIGN KEY (id_pago) REFERENCES pagos(id_pago)
);

CREATE TABLE cargos_extra (
    id_cargo_extra INT PRIMARY KEY IDENTITY(1,1),
    descripcion    VARCHAR(255)  NOT NULL,
    monto          DECIMAL(10,2) NOT NULL,
    id_reservacion INT           NOT NULL,
    FOREIGN KEY (id_reservacion) REFERENCES reservaciones(id_reservacion)
);

CREATE TABLE reembolsos (
    id_reembolso    INT PRIMARY KEY IDENTITY(1,1),
    fecha_reembolso DATETIME      NOT NULL,
    monto           DECIMAL(10,2) NOT NULL,
    motivo          VARCHAR(255),
    id_pago         INT           NOT NULL,
    FOREIGN KEY (id_pago) REFERENCES pagos(id_pago)
);

CREATE TABLE productos (
    id_producto INT PRIMARY KEY IDENTITY(1,1),
    nombre      VARCHAR(100)  NOT NULL,
    descripcion VARCHAR(255),
    precio      DECIMAL(10,2) NOT NULL,
    stock       INT           NOT NULL
);

CREATE TABLE ventas (
    id_venta   INT PRIMARY KEY IDENTITY(1,1),
    fecha_venta DATETIME      NOT NULL,
    total       DECIMAL(10,2) NOT NULL,
    id_usuario  INT           NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE detalle_venta (
    id_detalle_venta INT PRIMARY KEY IDENTITY(1,1),
    id_venta         INT           NOT NULL,
    id_producto      INT           NOT NULL,
    cantidad         INT           NOT NULL,
    subtotal         DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE login_auditoria (
    id_login   INT PRIMARY KEY IDENTITY(1,1),
    ip         VARCHAR(45)  NOT NULL,
    fecha_login DATETIME    NOT NULL,
    dispositivo VARCHAR(100),
    id_usuario  INT         NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE auditoria_reservaciones (
    id_auditoria    INT PRIMARY KEY IDENTITY(1,1),
    id_reservacion  INT,
    estado_anterior VARCHAR(50),
    estado_nuevo    VARCHAR(50),
    fecha_cambio    DATETIME     DEFAULT GETDATE(),
    usuario_sistema VARCHAR(100) DEFAULT SYSTEM_USER
);
GO

PRINT '>> Tablas creadas correctamente';
GO

-- =============================================
-- PASO 3: CONTROL DE ACCESO
-- =============================================

-- Login para la aplicacion Spring Boot
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'hotel_app')
    CREATE LOGIN hotel_app WITH PASSWORD = 'Hotel2024!';
GO

CREATE USER hotel_app FOR LOGIN hotel_app;
ALTER ROLE db_owner ADD MEMBER hotel_app;
GO

PRINT '>> Control de acceso configurado';
GO

-- =============================================
-- PASO 4: DATOS BASE (roles y catalogos)
-- =============================================

INSERT INTO roles (nombre, descripcion) VALUES
('ADMIN',         'Administrador del sistema'),
('RECEPCIONISTA', 'Personal de recepción'),
('CLIENTE',       'Cliente del hotel');

INSERT INTO metodos_pago (nombre) VALUES
('Efectivo'),
('Tarjeta de crédito'),
('Transferencia bancaria'),
('SINPE Móvil');

PRINT '>> Datos base insertados';
GO

-- =============================================
-- PASO 5: FUNCIONES
-- =============================================

-- F1: Calcular total de reservacion aplicando descuento
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
    FROM habitaciones
    WHERE id_habitacion = @idHabitacion

    SET @noches    = DATEDIFF(DAY, @fechaEntrada, @fechaSalida)
    SET @descuento = 0

    IF @idOferta IS NOT NULL
        SELECT @descuento = descuento
        FROM ofertas
        WHERE id_oferta  = @idOferta
          AND GETDATE() BETWEEN fecha_inicio AND fecha_fin

    SET @total = (@precioNoche * @noches) * (1 - @descuento / 100)
    RETURN ISNULL(@total, 0)
END
GO

-- F2: Verificar disponibilidad de habitacion en rango de fechas
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
      AND estado        NOT IN ('cancelada')
      AND fecha_entrada <  @fechaSalida
      AND fecha_salida  >  @fechaEntrada

    IF @conflictos > 0 RETURN 0
    RETURN 1
END
GO

-- F3: Total de ingresos por rango de fechas
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

PRINT '>> Funciones creadas correctamente';
GO

-- =============================================
-- PASO 6: PROCEDIMIENTOS ALMACENADOS
-- =============================================

-- SP1: Crear reservacion (proceso transaccional principal)
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

        -- Validar fechas
        IF @fechaEntrada >= @fechaSalida
        BEGIN
            SET @mensaje = 'ERROR: La fecha de entrada debe ser anterior a la fecha de salida'
            ROLLBACK TRANSACTION
            RETURN
        END

        IF @fechaEntrada < CAST(GETDATE() AS DATE)
        BEGIN
            SET @mensaje = 'ERROR: La fecha de entrada no puede ser en el pasado'
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Verificar disponibilidad usando funcion
        IF dbo.fn_HabitacionDisponible(@idHabitacion, @fechaEntrada, @fechaSalida) = 0
        BEGIN
            SET @mensaje = 'ERROR: La habitacion no esta disponible en esas fechas'
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Calcular total usando funcion
        DECLARE @total DECIMAL(10,2)
        SET @total = dbo.fn_CalcularTotalReservacion(
            @idHabitacion, @fechaEntrada, @fechaSalida, @idOferta
        )

        -- Insertar reservacion
        INSERT INTO reservaciones
            (fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion, id_oferta)
        VALUES
            (@fechaEntrada, @fechaSalida, 'confirmada', @total, @idUsuario, @idHabitacion, @idOferta)

        SET @mensaje = 'OK: Reservacion creada exitosamente. Total: ₡' + CAST(@total AS VARCHAR(20))
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

-- SP2: Procesar pago y generar factura automaticamente
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

        -- Verificar reservacion
        DECLARE @estadoRes VARCHAR(50)
        SELECT @estadoRes = estado
        FROM reservaciones
        WHERE id_reservacion = @idReservacion

        IF @estadoRes IS NULL
        BEGIN
            SET @mensaje = 'ERROR: La reservacion no existe'
            ROLLBACK TRANSACTION
            RETURN
        END

        IF @estadoRes = 'cancelada'
        BEGIN
            SET @mensaje = 'ERROR: No se puede pagar una reservacion cancelada'
            ROLLBACK TRANSACTION
            RETURN
        END

        IF @monto <= 0
        BEGIN
            SET @mensaje = 'ERROR: El monto debe ser mayor a cero'
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Registrar pago
        DECLARE @idPago INT

        INSERT INTO pagos (fecha_pago, monto, estado, id_reservacion, id_metodo_pago)
        VALUES (GETDATE(), @monto, 'completado', @idReservacion, @idMetodoPago)

        SET @idPago = SCOPE_IDENTITY()

        -- Generar factura con IVA 13%
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
        SELECT @estadoRes = estado
        FROM reservaciones
        WHERE id_reservacion = @idReservacion

        IF @estadoRes IS NULL
        BEGIN
            SET @mensaje = 'ERROR: Reservacion no encontrada'
            ROLLBACK TRANSACTION
            RETURN
        END

        IF @estadoRes = 'cancelada'
        BEGIN
            SET @mensaje = 'ERROR: La reservacion ya esta cancelada'
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Cancelar reservacion
        UPDATE reservaciones
        SET estado = 'cancelada'
        WHERE id_reservacion = @idReservacion

        -- Aplicar reembolso si se solicita
        IF @aplicarReembolso = 1
        BEGIN
            DECLARE @idPago    INT
            DECLARE @montoPago DECIMAL(10,2)

            SELECT TOP 1
                @idPago    = id_pago,
                @montoPago = monto
            FROM pagos
            WHERE id_reservacion = @idReservacion
              AND estado         = 'completado'
            ORDER BY fecha_pago DESC

            IF @idPago IS NOT NULL
            BEGIN
                INSERT INTO reembolsos (fecha_reembolso, monto, motivo, id_pago)
                VALUES (GETDATE(), @montoPago, @motivo, @idPago)

                UPDATE pagos
                SET estado = 'reembolsado'
                WHERE id_pago = @idPago
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

        -- Verificar stock
        DECLARE @stockActual    INT
        DECLARE @precioProducto DECIMAL(10,2)

        SELECT @stockActual    = stock,
               @precioProducto = precio
        FROM productos
        WHERE id_producto = @idProducto

        IF @stockActual IS NULL
        BEGIN
            SET @mensaje = 'ERROR: Producto no encontrado'
            ROLLBACK TRANSACTION
            RETURN
        END

        IF @stockActual < @cantidad
        BEGIN
            SET @mensaje = 'ERROR: Stock insuficiente. Disponible: ' + CAST(@stockActual AS VARCHAR(10))
            ROLLBACK TRANSACTION
            RETURN
        END

        -- Calcular subtotal
        DECLARE @subtotal DECIMAL(10,2) = @precioProducto * @cantidad

        -- Registrar venta
        DECLARE @idVenta INT

        INSERT INTO ventas (fecha_venta, total, id_usuario)
        VALUES (GETDATE(), @subtotal, @idUsuario)

        SET @idVenta = SCOPE_IDENTITY()

        -- Registrar detalle
        INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal)
        VALUES (@idVenta, @idProducto, @cantidad, @subtotal)

        -- Descontar stock
        UPDATE productos
        SET stock = stock - @cantidad
        WHERE id_producto = @idProducto

        SET @mensaje = 'OK: Venta registrada exitosamente. Total: ₡' + CAST(@subtotal AS VARCHAR(20))
        COMMIT TRANSACTION

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION
        SET @mensaje = 'ERROR: ' + ERROR_MESSAGE()
    END CATCH
END
GO

PRINT '>> Procedimientos almacenados creados correctamente';
GO

-- =============================================
-- PASO 7: TRIGGERS
-- =============================================

-- T1: Actualizar estado de habitacion segun reservaciones
CREATE OR ALTER TRIGGER trg_ActualizarEstadoHabitacion
ON reservaciones
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON

    -- Marcar como "ocupada" si el huesped ya entro hoy
    UPDATE habitaciones
    SET estado = 'ocupada'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion
        FROM inserted
        WHERE estado         = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )

    -- Marcar como "reservada" si la reservacion es futura (aun no entra)
    UPDATE habitaciones
    SET estado = 'reservada'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion
        FROM inserted
        WHERE estado        = 'confirmada'
          AND fecha_entrada > CAST(GETDATE() AS DATE)
    )
    AND id_habitacion NOT IN (
        SELECT id_habitacion FROM reservaciones
        WHERE estado         = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )

    -- Marcar como "disponible" si se cancelo y no hay otras reservas activas
    UPDATE habitaciones
    SET estado = 'disponible'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion
        FROM inserted
        WHERE estado = 'cancelada'
    )
    AND id_habitacion NOT IN (
        SELECT id_habitacion FROM reservaciones
        WHERE estado       = 'confirmada'
          AND fecha_salida > CAST(GETDATE() AS DATE)
    )
END
GO

-- T2: Auditoria de cambios de estado en reservaciones
CREATE OR ALTER TRIGGER trg_AuditoriaReservaciones
ON reservaciones
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO auditoria_reservaciones
        (id_reservacion, estado_anterior, estado_nuevo)
    SELECT
        i.id_reservacion,
        d.estado,
        i.estado
    FROM inserted i
    INNER JOIN deleted d ON i.id_reservacion = d.id_reservacion
    WHERE i.estado <> d.estado
END
GO

-- T3: Prevenir stock negativo en ventas
CREATE OR ALTER TRIGGER trg_ValidarStock
ON detalle_venta
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON

    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN productos p ON i.id_producto = p.id_producto
        WHERE p.stock < 0
    )
    BEGIN
        RAISERROR('ERROR: Stock insuficiente para completar la venta', 16, 1)
        ROLLBACK TRANSACTION
    END
END
GO

PRINT '>> Triggers creados correctamente';
GO

-- =============================================
-- PASO 8: DATOS DE PRUEBA
-- =============================================

-- Habitaciones
INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES
(101, 'individual',  45000, 'disponible'),
(102, 'doble',       75000, 'disponible'),
(201, 'suite',      150000, 'disponible'),
(202, 'doble',       75000, 'disponible'),
(301, 'penthouse',  250000, 'disponible');

-- Productos
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES
('Agua mineral',        'Botella 500ml',        1500,  100),
('Café',                'Taza de café',          2500,   50),
('Snack mixto',         'Bolsa de snacks',       3500,   75),
('Vino tinto',          'Copa de vino tinto',    8000,   30),
('Servicio lavandería', 'Por prenda',            5000,  200);

-- Ofertas
INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin) VALUES
('Temporada baja',  '15% de descuento en temporada baja',  15.00, '2026-01-01', '2026-06-30'),
('Fin de semana',   '10% descuento fines de semana',       10.00, '2026-01-01', '2026-12-31'),
('Estadía larga',   '20% descuento por 7 o más noches',   20.00, '2026-01-01', '2026-12-31');

PRINT '>> Datos de prueba insertados';
GO

-- =============================================
-- VERIFICACION FINAL
-- =============================================
PRINT '============================================='
PRINT 'SCRIPT COMPLETADO EXITOSAMENTE'
PRINT '============================================='
PRINT 'Tablas:                 15'
PRINT 'Funciones:               3'
PRINT 'Procedimientos:          4'
PRINT 'Triggers:                3'
PRINT 'Roles:                   3'
PRINT 'Metodos de pago:         4'
PRINT 'Habitaciones de prueba:  5'
PRINT 'Productos de prueba:     5'
PRINT 'Ofertas de prueba:       3'
PRINT '============================================='
GO

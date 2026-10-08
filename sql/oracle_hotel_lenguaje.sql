-- =============================================
-- HOTEL LENGUAJE - SCRIPT ORACLE PL/SQL
-- SC-504 Lenguajes de Base de Datos
-- Usuario: ADMIN | Schema: ProyectoLenguajes
-- Oracle Cloud ATP - Wallet connection
-- =============================================

-- =============================================
-- PASO 1: LIMPIAR OBJETOS EXISTENTES
-- =============================================

-- Eliminar tablas si existen (orden inverso por FK)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables ORDER BY table_name) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
    END LOOP;
END;
/

-- Eliminar secuencias
BEGIN
    FOR s IN (SELECT sequence_name FROM user_sequences) LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

-- Eliminar vistas
BEGIN
    FOR v IN (SELECT view_name FROM user_views) LOOP
        EXECUTE IMMEDIATE 'DROP VIEW ' || v.view_name;
    END LOOP;
END;
/

-- Eliminar procedimientos
BEGIN
    FOR p IN (SELECT object_name FROM user_objects WHERE object_type = 'PROCEDURE') LOOP
        EXECUTE IMMEDIATE 'DROP PROCEDURE ' || p.object_name;
    END LOOP;
END;
/

-- Eliminar funciones
BEGIN
    FOR f IN (SELECT object_name FROM user_objects WHERE object_type = 'FUNCTION') LOOP
        EXECUTE IMMEDIATE 'DROP FUNCTION ' || f.object_name;
    END LOOP;
END;
/

-- Eliminar paquetes
BEGIN
    FOR pk IN (SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE') LOOP
        EXECUTE IMMEDIATE 'DROP PACKAGE ' || pk.object_name;
    END LOOP;
END;
/

-- =============================================
-- PASO 2: CREAR TABLAS
-- =============================================

CREATE TABLE roles (
    id_rol      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR2(50)  NOT NULL,
    descripcion VARCHAR2(255)
);

CREATE TABLE usuarios (
    id_usuario     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR2(100) NOT NULL,
    apellido_1     VARCHAR2(100) NOT NULL,
    apellido_2     VARCHAR2(100),
    identificacion VARCHAR2(50)  NOT NULL,
    correo         VARCHAR2(150) NOT NULL,
    telefono       VARCHAR2(20),
    username       VARCHAR2(50)  NOT NULL,
    contrasena     VARCHAR2(255) NOT NULL,
    fecha_registro DATE          NOT NULL,
    id_rol         NUMBER,
    CONSTRAINT fk_usuario_rol    FOREIGN KEY (id_rol)     REFERENCES roles(id_rol),
    CONSTRAINT uq_identificacion UNIQUE (identificacion),
    CONSTRAINT uq_correo         UNIQUE (correo),
    CONSTRAINT uq_username       UNIQUE (username)
);

CREATE TABLE habitaciones (
    id_habitacion NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    numero        NUMBER        NOT NULL,
    tipo          VARCHAR2(50)  NOT NULL,
    precio_noche  NUMBER(10,2)  NOT NULL,
    estado        VARCHAR2(50)  NOT NULL,
    CONSTRAINT uq_habitacion_numero UNIQUE (numero)
);

CREATE TABLE ofertas (
    id_oferta    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo       VARCHAR2(100) NOT NULL,
    descripcion  VARCHAR2(255),
    descuento    NUMBER(5,2)   NOT NULL,
    fecha_inicio DATE          NOT NULL,
    fecha_fin    DATE          NOT NULL
);

CREATE TABLE reservaciones (
    id_reservacion NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_entrada  DATE         NOT NULL,
    fecha_salida   DATE         NOT NULL,
    estado         VARCHAR2(50) NOT NULL,
    total_pago     NUMBER(10,2),
    id_usuario     NUMBER       NOT NULL,
    id_habitacion  NUMBER       NOT NULL,
    id_oferta      NUMBER,
    CONSTRAINT fk_res_usuario    FOREIGN KEY (id_usuario)    REFERENCES usuarios(id_usuario),
    CONSTRAINT fk_res_habitacion FOREIGN KEY (id_habitacion) REFERENCES habitaciones(id_habitacion),
    CONSTRAINT fk_res_oferta     FOREIGN KEY (id_oferta)     REFERENCES ofertas(id_oferta)
);

CREATE TABLE metodos_pago (
    id_metodo_pago NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre         VARCHAR2(50) NOT NULL
);

CREATE TABLE pagos (
    id_pago        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_pago     TIMESTAMP    NOT NULL,
    monto          NUMBER(10,2) NOT NULL,
    estado         VARCHAR2(50) NOT NULL,
    id_reservacion NUMBER       NOT NULL,
    id_metodo_pago NUMBER       NOT NULL,
    CONSTRAINT fk_pago_reservacion  FOREIGN KEY (id_reservacion) REFERENCES reservaciones(id_reservacion),
    CONSTRAINT fk_pago_metodo       FOREIGN KEY (id_metodo_pago) REFERENCES metodos_pago(id_metodo_pago)
);

CREATE TABLE facturas (
    id_factura    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_emision TIMESTAMP    NOT NULL,
    subtotal      NUMBER(10,2) NOT NULL,
    impuesto      NUMBER(10,2) NOT NULL,
    total         NUMBER(10,2) NOT NULL,
    id_pago       NUMBER       NOT NULL,
    CONSTRAINT fk_factura_pago FOREIGN KEY (id_pago) REFERENCES pagos(id_pago)
);

CREATE TABLE cargos_extra (
    id_cargo_extra NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    descripcion    VARCHAR2(255) NOT NULL,
    monto          NUMBER(10,2)  NOT NULL,
    id_reservacion NUMBER        NOT NULL,
    CONSTRAINT fk_cargo_reservacion FOREIGN KEY (id_reservacion) REFERENCES reservaciones(id_reservacion)
);

CREATE TABLE reembolsos (
    id_reembolso    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_reembolso TIMESTAMP    NOT NULL,
    monto           NUMBER(10,2) NOT NULL,
    motivo          VARCHAR2(255),
    id_pago         NUMBER       NOT NULL,
    CONSTRAINT fk_reembolso_pago FOREIGN KEY (id_pago) REFERENCES pagos(id_pago)
);

CREATE TABLE productos (
    id_producto NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR2(100) NOT NULL,
    descripcion VARCHAR2(255),
    precio      NUMBER(10,2)  NOT NULL,
    stock       NUMBER        NOT NULL
);

CREATE TABLE ventas (
    id_venta    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    fecha_venta TIMESTAMP    NOT NULL,
    total       NUMBER(10,2) NOT NULL,
    id_usuario  NUMBER       NOT NULL,
    CONSTRAINT fk_venta_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE detalle_venta (
    id_detalle_venta NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta         NUMBER       NOT NULL,
    id_producto      NUMBER       NOT NULL,
    cantidad         NUMBER       NOT NULL,
    subtotal         NUMBER(10,2) NOT NULL,
    CONSTRAINT fk_detalle_venta    FOREIGN KEY (id_venta)    REFERENCES ventas(id_venta),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

CREATE TABLE login_auditoria (
    id_login    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ip          VARCHAR2(45)  NOT NULL,
    fecha_login TIMESTAMP     NOT NULL,
    dispositivo VARCHAR2(100),
    id_usuario  NUMBER        NOT NULL,
    CONSTRAINT fk_login_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario)
);

CREATE TABLE auditoria_reservaciones (
    id_auditoria    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_reservacion  NUMBER,
    estado_anterior VARCHAR2(50),
    estado_nuevo    VARCHAR2(50),
    fecha_cambio    TIMESTAMP    DEFAULT SYSTIMESTAMP,
    usuario_sistema VARCHAR2(100) DEFAULT USER
);

CREATE TABLE auditoria_usuarios (
    id_auditoria    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario      NUMBER,
    accion          VARCHAR2(50),
    fecha           TIMESTAMP    DEFAULT SYSTIMESTAMP,
    usuario_sistema VARCHAR2(100) DEFAULT USER
);

COMMIT;
/

-- =============================================
-- PASO 3: DATOS BASE
-- =============================================

INSERT INTO roles (nombre, descripcion) VALUES ('ADMIN', 'Administrador del sistema');
INSERT INTO roles (nombre, descripcion) VALUES ('RECEPCIONISTA', 'Personal de recepcion');
INSERT INTO roles (nombre, descripcion) VALUES ('CLIENTE', 'Cliente del hotel');

INSERT INTO metodos_pago (nombre) VALUES ('Efectivo');
INSERT INTO metodos_pago (nombre) VALUES ('Tarjeta de credito');
INSERT INTO metodos_pago (nombre) VALUES ('Transferencia bancaria');
INSERT INTO metodos_pago (nombre) VALUES ('SINPE Movil');

-- Usuario admin (contrasena: admin123)
INSERT INTO usuarios (nombre, apellido_1, apellido_2, identificacion, correo, telefono, username, contrasena, fecha_registro, id_rol)
VALUES ('Admin', 'Hotel', 'Sistema', '000000001', 'admin@hotel.com', '88888888', 'admin',
        '$2a$10$slYQmyNdgTY18LGvgxPwsOWGMNGGnBbZDrivuOYTl36G4bFTIIGWS', SYSDATE, 1);

INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (101, 'individual',  45000, 'disponible');
INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (102, 'doble',       75000, 'disponible');
INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (201, 'suite',      150000, 'disponible');
INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (202, 'doble',       75000, 'disponible');
INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (301, 'penthouse',  250000, 'disponible');

INSERT INTO productos (nombre, descripcion, precio, stock) VALUES ('Agua mineral', 'Botella 500ml', 1500, 100);
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES ('Cafe', 'Taza de cafe', 2500, 50);
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES ('Snack mixto', 'Bolsa de snacks', 3500, 75);
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES ('Vino tinto', 'Copa de vino tinto', 8000, 30);
INSERT INTO productos (nombre, descripcion, precio, stock) VALUES ('Servicio lavanderia', 'Por prenda', 5000, 200);

INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin)
VALUES ('Temporada baja', '15% de descuento en temporada baja', 15.00, DATE '2026-01-01', DATE '2026-12-31');
INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin)
VALUES ('Fin de semana', '10% descuento fines de semana', 10.00, DATE '2026-01-01', DATE '2026-12-31');
INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin)
VALUES ('Estadia larga', '20% descuento por 7 o mas noches', 20.00, DATE '2026-01-01', DATE '2026-12-31');

COMMIT;
/

-- =============================================
-- PASO 4: FUNCIONES (F1-F8)
-- =============================================

-- F1: Calcular total de reservacion con descuento
CREATE OR REPLACE FUNCTION fn_CalcularTotalReservacion(
    p_idHabitacion NUMBER,
    p_fechaEntrada DATE,
    p_fechaSalida  DATE,
    p_idOferta     NUMBER
) RETURN NUMBER IS
    v_precioNoche NUMBER(10,2);
    v_noches      NUMBER;
    v_descuento   NUMBER(5,2) := 0;
    v_total       NUMBER(10,2);
BEGIN
    SELECT precio_noche INTO v_precioNoche
    FROM habitaciones WHERE id_habitacion = p_idHabitacion;

    v_noches := p_fechaSalida - p_fechaEntrada;

    IF p_idOferta IS NOT NULL THEN
        BEGIN
            SELECT descuento INTO v_descuento
            FROM ofertas
            WHERE id_oferta = p_idOferta
              AND SYSDATE BETWEEN fecha_inicio AND fecha_fin;
        EXCEPTION WHEN NO_DATA_FOUND THEN v_descuento := 0;
        END;
    END IF;

    v_total := (v_precioNoche * v_noches) * (1 - v_descuento / 100);
    RETURN NVL(v_total, 0);
EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 0;
END;
/

-- F2: Verificar disponibilidad de habitacion
CREATE OR REPLACE FUNCTION fn_HabitacionDisponible(
    p_idHabitacion NUMBER,
    p_fechaEntrada DATE,
    p_fechaSalida  DATE
) RETURN NUMBER IS
    v_conflictos NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_conflictos
    FROM reservaciones
    WHERE id_habitacion = p_idHabitacion
      AND estado NOT IN ('cancelada')
      AND fecha_entrada < p_fechaSalida
      AND fecha_salida  > p_fechaEntrada;

    IF v_conflictos > 0 THEN RETURN 0; END IF;
    RETURN 1;
END;
/

-- F3: Total de ingresos por rango de fechas
CREATE OR REPLACE FUNCTION fn_TotalIngresosPorFecha(
    p_fechaInicio DATE,
    p_fechaFin    DATE
) RETURN NUMBER IS
    v_total NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(monto), 0) INTO v_total
    FROM pagos
    WHERE estado = 'completado'
      AND TRUNC(fecha_pago) BETWEEN p_fechaInicio AND p_fechaFin;
    RETURN v_total;
END;
/

-- F4: Reservaciones activas de un usuario
CREATE OR REPLACE FUNCTION fn_ReservacionesActivasUsuario(p_idUsuario NUMBER)
RETURN NUMBER IS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM reservaciones
    WHERE id_usuario = p_idUsuario
      AND estado NOT IN ('cancelada', 'finalizada');
    RETURN NVL(v_total, 0);
END;
/

-- F5: Ingresos totales de una habitacion
CREATE OR REPLACE FUNCTION fn_IngresosTotalesHabitacion(p_idHabitacion NUMBER)
RETURN NUMBER IS
    v_total NUMBER(10,2);
BEGIN
    SELECT NVL(SUM(p.monto), 0) INTO v_total
    FROM pagos p
    INNER JOIN reservaciones r ON p.id_reservacion = r.id_reservacion
    WHERE r.id_habitacion = p_idHabitacion
      AND p.estado = 'completado';
    RETURN v_total;
END;
/

-- F6: Verificar si una oferta esta vigente
CREATE OR REPLACE FUNCTION fn_OfertaVigente(p_idOferta NUMBER)
RETURN NUMBER IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM ofertas
    WHERE id_oferta = p_idOferta
      AND SYSDATE BETWEEN fecha_inicio AND fecha_fin;
    IF v_count > 0 THEN RETURN 1; END IF;
    RETURN 0;
END;
/

-- F7: Total de noches de una reservacion
CREATE OR REPLACE FUNCTION fn_TotalNochesReservacion(p_idReservacion NUMBER)
RETURN NUMBER IS
    v_noches NUMBER;
BEGIN
    SELECT (fecha_salida - fecha_entrada) INTO v_noches
    FROM reservaciones WHERE id_reservacion = p_idReservacion;
    RETURN NVL(v_noches, 0);
EXCEPTION WHEN NO_DATA_FOUND THEN RETURN 0;
END;
/

-- F8: Porcentaje de ocupacion del hotel
CREATE OR REPLACE FUNCTION fn_PorcentajeOcupacion
RETURN NUMBER IS
    v_total    NUMBER;
    v_ocupadas NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total FROM habitaciones;
    SELECT COUNT(*) INTO v_ocupadas FROM habitaciones
    WHERE estado IN ('ocupada', 'reservada');
    IF v_total = 0 THEN RETURN 0; END IF;
    RETURN ROUND((v_ocupadas / v_total) * 100, 2);
END;
/

-- =============================================
-- PASO 5: PAQUETES (PKG)
-- =============================================

-- PKG1: Paquete de gestion de reservaciones
CREATE OR REPLACE PACKAGE pkg_reservaciones AS
    PROCEDURE crear(p_idUsuario NUMBER, p_idHabitacion NUMBER, p_fechaEntrada DATE,
                    p_fechaSalida DATE, p_idOferta NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE cancelar(p_idReservacion NUMBER, p_motivo VARCHAR2,
                       p_aplicarReembolso NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE obtener_todas(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_por_usuario(p_idUsuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_por_id(p_idReservacion NUMBER, p_cursor OUT SYS_REFCURSOR);
END pkg_reservaciones;
/

CREATE OR REPLACE PACKAGE BODY pkg_reservaciones AS

    PROCEDURE crear(p_idUsuario NUMBER, p_idHabitacion NUMBER, p_fechaEntrada DATE,
                    p_fechaSalida DATE, p_idOferta NUMBER, p_mensaje OUT VARCHAR2) IS
        v_total NUMBER(10,2);
    BEGIN
        IF p_fechaEntrada >= p_fechaSalida THEN
            p_mensaje := 'ERROR: Fecha entrada debe ser anterior a fecha salida'; RETURN;
        END IF;
        IF p_fechaEntrada < TRUNC(SYSDATE) THEN
            p_mensaje := 'ERROR: La fecha de entrada no puede ser en el pasado'; RETURN;
        END IF;
        IF fn_HabitacionDisponible(p_idHabitacion, p_fechaEntrada, p_fechaSalida) = 0 THEN
            p_mensaje := 'ERROR: Habitacion no disponible en esas fechas'; RETURN;
        END IF;

        v_total := fn_CalcularTotalReservacion(p_idHabitacion, p_fechaEntrada, p_fechaSalida, p_idOferta);

        INSERT INTO reservaciones (fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion, id_oferta)
        VALUES (p_fechaEntrada, p_fechaSalida, 'confirmada', v_total, p_idUsuario, p_idHabitacion, p_idOferta);

        COMMIT;
        p_mensaje := 'OK: Reservacion creada. Total: ' || TO_CHAR(v_total);
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE cancelar(p_idReservacion NUMBER, p_motivo VARCHAR2,
                       p_aplicarReembolso NUMBER, p_mensaje OUT VARCHAR2) IS
        v_estado   VARCHAR2(50);
        v_idPago   NUMBER;
        v_montoPago NUMBER(10,2);
    BEGIN
        SELECT estado INTO v_estado FROM reservaciones WHERE id_reservacion = p_idReservacion;

        IF v_estado = 'cancelada' THEN
            p_mensaje := 'ERROR: La reservacion ya esta cancelada'; RETURN;
        END IF;

        UPDATE reservaciones SET estado = 'cancelada' WHERE id_reservacion = p_idReservacion;

        IF p_aplicarReembolso = 1 THEN
            BEGIN
                SELECT id_pago, monto INTO v_idPago, v_montoPago
                FROM (SELECT id_pago, monto FROM pagos
                      WHERE id_reservacion = p_idReservacion AND estado = 'completado'
                      ORDER BY fecha_pago DESC)
                WHERE ROWNUM = 1;

                INSERT INTO reembolsos (fecha_reembolso, monto, motivo, id_pago)
                VALUES (SYSTIMESTAMP, v_montoPago, p_motivo, v_idPago);

                UPDATE pagos SET estado = 'reembolsado' WHERE id_pago = v_idPago;
            EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
            END;
        END IF;

        COMMIT;
        p_mensaje := 'OK: Reservacion cancelada exitosamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE obtener_todas(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT r.id_reservacion, u.nombre || ' ' || u.apellido_1 AS huesped,
                   h.numero AS habitacion, h.tipo, r.fecha_entrada, r.fecha_salida,
                   r.total_pago, r.estado
            FROM reservaciones r
            INNER JOIN usuarios u ON r.id_usuario = u.id_usuario
            INNER JOIN habitaciones h ON r.id_habitacion = h.id_habitacion
            ORDER BY r.fecha_entrada DESC;
    END;

    PROCEDURE obtener_por_usuario(p_idUsuario NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT r.id_reservacion, h.numero AS habitacion, h.tipo,
                   r.fecha_entrada, r.fecha_salida, r.total_pago, r.estado
            FROM reservaciones r
            INNER JOIN habitaciones h ON r.id_habitacion = h.id_habitacion
            WHERE r.id_usuario = p_idUsuario
            ORDER BY r.fecha_entrada DESC;
    END;

    PROCEDURE obtener_por_id(p_idReservacion NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT r.id_reservacion, u.nombre || ' ' || u.apellido_1 AS huesped,
                   u.identificacion, h.numero, h.tipo, h.precio_noche,
                   r.fecha_entrada, r.fecha_salida, r.total_pago, r.estado,
                   o.titulo AS oferta, o.descuento
            FROM reservaciones r
            INNER JOIN usuarios u ON r.id_usuario = u.id_usuario
            INNER JOIN habitaciones h ON r.id_habitacion = h.id_habitacion
            LEFT JOIN ofertas o ON r.id_oferta = o.id_oferta
            WHERE r.id_reservacion = p_idReservacion;
    END;

END pkg_reservaciones;
/

-- PKG2: Paquete de gestion de pagos
CREATE OR REPLACE PACKAGE pkg_pagos AS
    PROCEDURE procesar(p_idReservacion NUMBER, p_idMetodoPago NUMBER,
                       p_monto NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE historial(p_fechaInicio DATE, p_fechaFin DATE, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_por_reservacion(p_idReservacion NUMBER, p_cursor OUT SYS_REFCURSOR);
END pkg_pagos;
/

CREATE OR REPLACE PACKAGE BODY pkg_pagos AS

    PROCEDURE procesar(p_idReservacion NUMBER, p_idMetodoPago NUMBER,
                       p_monto NUMBER, p_mensaje OUT VARCHAR2) IS
        v_estado   VARCHAR2(50);
        v_idPago   NUMBER;
        v_impuesto NUMBER(10,2);
        v_subtotal NUMBER(10,2);
    BEGIN
        SELECT estado INTO v_estado FROM reservaciones WHERE id_reservacion = p_idReservacion;

        IF v_estado = 'cancelada' THEN
            p_mensaje := 'ERROR: No se puede pagar reservacion cancelada'; RETURN;
        END IF;
        IF p_monto <= 0 THEN
            p_mensaje := 'ERROR: El monto debe ser mayor a cero'; RETURN;
        END IF;

        INSERT INTO pagos (fecha_pago, monto, estado, id_reservacion, id_metodo_pago)
        VALUES (SYSTIMESTAMP, p_monto, 'completado', p_idReservacion, p_idMetodoPago)
        RETURNING id_pago INTO v_idPago;

        v_impuesto := ROUND(p_monto * 0.13, 2);
        v_subtotal := ROUND(p_monto - v_impuesto, 2);

        INSERT INTO facturas (fecha_emision, subtotal, impuesto, total, id_pago)
        VALUES (SYSTIMESTAMP, v_subtotal, v_impuesto, p_monto, v_idPago);

        UPDATE reservaciones SET estado = 'pagada' WHERE id_reservacion = p_idReservacion;

        COMMIT;
        p_mensaje := 'OK: Pago procesado y factura generada. ID: ' || v_idPago;
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE historial(p_fechaInicio DATE, p_fechaFin DATE, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT p.id_pago, p.fecha_pago, p.monto, p.estado,
                   u.nombre || ' ' || u.apellido_1 AS huesped,
                   mp.nombre AS metodo_pago
            FROM pagos p
            INNER JOIN reservaciones r ON p.id_reservacion = r.id_reservacion
            INNER JOIN usuarios u ON r.id_usuario = u.id_usuario
            INNER JOIN metodos_pago mp ON p.id_metodo_pago = mp.id_metodo_pago
            WHERE TRUNC(p.fecha_pago) BETWEEN p_fechaInicio AND p_fechaFin
            ORDER BY p.fecha_pago DESC;
    END;

    PROCEDURE obtener_por_reservacion(p_idReservacion NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT p.id_pago, p.fecha_pago, p.monto, p.estado, mp.nombre AS metodo
            FROM pagos p
            INNER JOIN metodos_pago mp ON p.id_metodo_pago = mp.id_metodo_pago
            WHERE p.id_reservacion = p_idReservacion
            ORDER BY p.fecha_pago DESC;
    END;

END pkg_pagos;
/

-- PKG3: Paquete de gestion de usuarios
CREATE OR REPLACE PACKAGE pkg_usuarios AS
    PROCEDURE obtener_todos(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_por_id(p_idUsuario NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_por_username(p_username VARCHAR2, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE actualizar(p_idUsuario NUMBER, p_nombre VARCHAR2, p_apellido1 VARCHAR2,
                         p_apellido2 VARCHAR2, p_correo VARCHAR2, p_telefono VARCHAR2,
                         p_idRol NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE eliminar(p_idUsuario NUMBER, p_mensaje OUT VARCHAR2);
END pkg_usuarios;
/

CREATE OR REPLACE PACKAGE BODY pkg_usuarios AS

    PROCEDURE obtener_todos(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT u.id_usuario, u.nombre, u.apellido_1, u.apellido_2,
                   u.identificacion, u.correo, u.telefono, u.username,
                   u.fecha_registro, r.nombre AS rol
            FROM usuarios u
            LEFT JOIN roles r ON u.id_rol = r.id_rol
            ORDER BY u.nombre;
    END;

    PROCEDURE obtener_por_id(p_idUsuario NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT u.id_usuario, u.nombre, u.apellido_1, u.apellido_2,
                   u.identificacion, u.correo, u.telefono, u.username,
                   u.contrasena, u.fecha_registro, r.nombre AS rol, u.id_rol
            FROM usuarios u
            LEFT JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.id_usuario = p_idUsuario;
    END;

    PROCEDURE obtener_por_username(p_username VARCHAR2, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT u.id_usuario, u.nombre, u.apellido_1, u.contrasena,
                   u.username, r.nombre AS rol
            FROM usuarios u
            LEFT JOIN roles r ON u.id_rol = r.id_rol
            WHERE u.username = p_username;
    END;

    PROCEDURE actualizar(p_idUsuario NUMBER, p_nombre VARCHAR2, p_apellido1 VARCHAR2,
                         p_apellido2 VARCHAR2, p_correo VARCHAR2, p_telefono VARCHAR2,
                         p_idRol NUMBER, p_mensaje OUT VARCHAR2) IS
    BEGIN
        UPDATE usuarios
        SET nombre = p_nombre, apellido_1 = p_apellido1, apellido_2 = p_apellido2,
            correo = p_correo, telefono = p_telefono, id_rol = p_idRol
        WHERE id_usuario = p_idUsuario;
        COMMIT;
        p_mensaje := 'OK: Usuario actualizado correctamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE eliminar(p_idUsuario NUMBER, p_mensaje OUT VARCHAR2) IS
        v_activas NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_activas FROM reservaciones
        WHERE id_usuario = p_idUsuario AND estado NOT IN ('cancelada', 'finalizada', 'pagada');
        IF v_activas > 0 THEN
            p_mensaje := 'ERROR: El usuario tiene reservaciones activas'; RETURN;
        END IF;
        DELETE FROM usuarios WHERE id_usuario = p_idUsuario;
        COMMIT;
        p_mensaje := 'OK: Usuario eliminado correctamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK;
        p_mensaje := 'ERROR: ' || SQLERRM;
    END;

END pkg_usuarios;
/

-- PKG4: Paquete de gestion de habitaciones
CREATE OR REPLACE PACKAGE pkg_habitaciones AS
    PROCEDURE obtener_todas(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE obtener_disponibles(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE crear(p_numero NUMBER, p_tipo VARCHAR2, p_precioNoche NUMBER,
                    p_estado VARCHAR2, p_mensaje OUT VARCHAR2);
    PROCEDURE actualizar(p_idHabitacion NUMBER, p_tipo VARCHAR2, p_precioNoche NUMBER,
                         p_estado VARCHAR2, p_mensaje OUT VARCHAR2);
    PROCEDURE eliminar(p_idHabitacion NUMBER, p_mensaje OUT VARCHAR2);
    PROCEDURE disponibles_por_fechas(p_fechaEntrada DATE, p_fechaSalida DATE, p_cursor OUT SYS_REFCURSOR);
END pkg_habitaciones;
/

CREATE OR REPLACE PACKAGE BODY pkg_habitaciones AS

    PROCEDURE obtener_todas(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_habitacion, numero, tipo, precio_noche, estado,
                   fn_IngresosTotalesHabitacion(id_habitacion) AS ingresos_totales
            FROM habitaciones ORDER BY numero;
    END;

    PROCEDURE obtener_disponibles(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_habitacion, numero, tipo, precio_noche, estado
            FROM habitaciones WHERE estado = 'disponible' ORDER BY numero;
    END;

    PROCEDURE crear(p_numero NUMBER, p_tipo VARCHAR2, p_precioNoche NUMBER,
                    p_estado VARCHAR2, p_mensaje OUT VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM habitaciones WHERE numero = p_numero;
        IF v_count > 0 THEN
            p_mensaje := 'ERROR: Ya existe una habitacion con ese numero'; RETURN;
        END IF;
        INSERT INTO habitaciones (numero, tipo, precio_noche, estado)
        VALUES (p_numero, p_tipo, p_precioNoche, p_estado);
        COMMIT;
        p_mensaje := 'OK: Habitacion creada correctamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK; p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE actualizar(p_idHabitacion NUMBER, p_tipo VARCHAR2, p_precioNoche NUMBER,
                         p_estado VARCHAR2, p_mensaje OUT VARCHAR2) IS
    BEGIN
        UPDATE habitaciones
        SET tipo = p_tipo, precio_noche = p_precioNoche, estado = p_estado
        WHERE id_habitacion = p_idHabitacion;
        COMMIT;
        p_mensaje := 'OK: Habitacion actualizada correctamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK; p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE eliminar(p_idHabitacion NUMBER, p_mensaje OUT VARCHAR2) IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_count FROM reservaciones
        WHERE id_habitacion = p_idHabitacion AND estado NOT IN ('cancelada');
        IF v_count > 0 THEN
            p_mensaje := 'ERROR: La habitacion tiene reservaciones activas'; RETURN;
        END IF;
        DELETE FROM habitaciones WHERE id_habitacion = p_idHabitacion;
        COMMIT;
        p_mensaje := 'OK: Habitacion eliminada correctamente';
    EXCEPTION WHEN OTHERS THEN
        ROLLBACK; p_mensaje := 'ERROR: ' || SQLERRM;
    END;

    PROCEDURE disponibles_por_fechas(p_fechaEntrada DATE, p_fechaSalida DATE, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT id_habitacion, numero, tipo, precio_noche, estado
            FROM habitaciones
            WHERE id_habitacion NOT IN (
                SELECT id_habitacion FROM reservaciones
                WHERE estado NOT IN ('cancelada')
                  AND fecha_entrada < p_fechaSalida
                  AND fecha_salida  > p_fechaEntrada
            )
            ORDER BY numero;
    END;

END pkg_habitaciones;
/

-- PKG5: Paquete de reportes con cursores
CREATE OR REPLACE PACKAGE pkg_reportes AS
    PROCEDURE reporte_ocupacion(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE reporte_ventas_productos(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE reporte_reservaciones_usuario(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE dashboard_general(p_cursor OUT SYS_REFCURSOR);
    PROCEDURE ingresos_por_mes(p_cursor OUT SYS_REFCURSOR);
END pkg_reportes;
/

CREATE OR REPLACE PACKAGE BODY pkg_reportes AS

    PROCEDURE reporte_ocupacion(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT h.numero, h.tipo, h.estado,
                   COUNT(r.id_reservacion) AS total_reservas,
                   fn_IngresosTotalesHabitacion(h.id_habitacion) AS ingresos_totales
            FROM habitaciones h
            LEFT JOIN reservaciones r ON h.id_habitacion = r.id_habitacion
            GROUP BY h.id_habitacion, h.numero, h.tipo, h.estado
            ORDER BY ingresos_totales DESC;
    END;

    PROCEDURE reporte_ventas_productos(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT p.nombre, p.precio, p.stock,
                   NVL(SUM(dv.cantidad), 0) AS unidades_vendidas,
                   NVL(SUM(dv.subtotal), 0) AS ingresos_totales
            FROM productos p
            LEFT JOIN detalle_venta dv ON p.id_producto = dv.id_producto
            GROUP BY p.id_producto, p.nombre, p.precio, p.stock
            ORDER BY ingresos_totales DESC;
    END;

    PROCEDURE reporte_reservaciones_usuario(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT u.nombre || ' ' || u.apellido_1 AS huesped,
                   COUNT(r.id_reservacion) AS total_reservaciones,
                   NVL(SUM(p.monto), 0) AS total_pagado
            FROM usuarios u
            LEFT JOIN reservaciones r ON u.id_usuario = r.id_usuario
            LEFT JOIN pagos p ON r.id_reservacion = p.id_reservacion AND p.estado = 'completado'
            GROUP BY u.id_usuario, u.nombre, u.apellido_1
            ORDER BY total_pagado DESC;
    END;

    PROCEDURE dashboard_general(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT
                (SELECT COUNT(*) FROM usuarios) AS total_usuarios,
                (SELECT COUNT(*) FROM habitaciones) AS total_habitaciones,
                (SELECT COUNT(*) FROM habitaciones WHERE estado = 'disponible') AS habitaciones_disponibles,
                (SELECT COUNT(*) FROM habitaciones WHERE estado = 'ocupada') AS habitaciones_ocupadas,
                (SELECT COUNT(*) FROM reservaciones WHERE estado NOT IN ('cancelada')) AS reservaciones_activas,
                (SELECT NVL(SUM(monto),0) FROM pagos WHERE estado = 'completado') AS ingresos_totales,
                fn_PorcentajeOcupacion() AS porcentaje_ocupacion
            FROM DUAL;
    END;

    PROCEDURE ingresos_por_mes(p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
        OPEN p_cursor FOR
            SELECT EXTRACT(YEAR FROM fecha_pago) AS anio,
                   EXTRACT(MONTH FROM fecha_pago) AS mes,
                   TO_CHAR(fecha_pago, 'Month') AS nombre_mes,
                   COUNT(*) AS total_pagos,
                   SUM(monto) AS ingresos_totales,
                   ROUND(AVG(monto), 2) AS promedio
            FROM pagos WHERE estado = 'completado'
            GROUP BY EXTRACT(YEAR FROM fecha_pago),
                     EXTRACT(MONTH FROM fecha_pago),
                     TO_CHAR(fecha_pago, 'Month')
            ORDER BY anio DESC, mes DESC;
    END;

END pkg_reportes;
/

-- =============================================
-- PASO 6: PROCEDIMIENTOS ADICIONALES
-- =============================================

-- SP: Registrar venta con control de stock
CREATE OR REPLACE PROCEDURE sp_RegistrarVenta(
    p_idUsuario  NUMBER,
    p_idProducto NUMBER,
    p_cantidad   NUMBER,
    p_mensaje    OUT VARCHAR2
) IS
    v_stock   NUMBER;
    v_precio  NUMBER(10,2);
    v_subtotal NUMBER(10,2);
    v_idVenta NUMBER;
BEGIN
    SELECT stock, precio INTO v_stock, v_precio
    FROM productos WHERE id_producto = p_idProducto;

    IF v_stock < p_cantidad THEN
        p_mensaje := 'ERROR: Stock insuficiente. Disponible: ' || v_stock; RETURN;
    END IF;

    v_subtotal := v_precio * p_cantidad;

    INSERT INTO ventas (fecha_venta, total, id_usuario)
    VALUES (SYSTIMESTAMP, v_subtotal, p_idUsuario)
    RETURNING id_venta INTO v_idVenta;

    INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal)
    VALUES (v_idVenta, p_idProducto, p_cantidad, v_subtotal);

    UPDATE productos SET stock = stock - p_cantidad WHERE id_producto = p_idProducto;

    COMMIT;
    p_mensaje := 'OK: Venta registrada. Total: ' || v_subtotal;
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    p_mensaje := 'ERROR: ' || SQLERRM;
END;
/

-- SP: Generar cargo extra
CREATE OR REPLACE PROCEDURE sp_GenerarCargoExtra(
    p_idReservacion NUMBER,
    p_descripcion   VARCHAR2,
    p_monto         NUMBER,
    p_mensaje       OUT VARCHAR2
) IS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM reservaciones
    WHERE id_reservacion = p_idReservacion AND estado = 'confirmada';

    IF v_count = 0 THEN
        p_mensaje := 'ERROR: Reservacion no existe o no esta activa'; RETURN;
    END IF;

    INSERT INTO cargos_extra (descripcion, monto, id_reservacion)
    VALUES (p_descripcion, p_monto, p_idReservacion);

    COMMIT;
    p_mensaje := 'OK: Cargo extra registrado correctamente';
EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    p_mensaje := 'ERROR: ' || SQLERRM;
END;
/

-- =============================================
-- PASO 7: VISTAS (10 vistas)
-- =============================================

CREATE OR REPLACE VIEW vw_ReservacionesActivas AS
SELECT r.id_reservacion,
       u.nombre || ' ' || u.apellido_1 AS huesped,
       u.identificacion, u.correo,
       h.numero AS habitacion, h.tipo AS tipo_habitacion,
       r.fecha_entrada, r.fecha_salida,
       (r.fecha_salida - r.fecha_entrada) AS noches,
       r.total_pago, r.estado,
       o.titulo AS oferta_aplicada, o.descuento
FROM reservaciones r
INNER JOIN usuarios u ON r.id_usuario = u.id_usuario
INNER JOIN habitaciones h ON r.id_habitacion = h.id_habitacion
LEFT JOIN ofertas o ON r.id_oferta = o.id_oferta
WHERE r.estado NOT IN ('cancelada');
/

CREATE OR REPLACE VIEW vw_HabitacionesDisponibilidad AS
SELECT h.id_habitacion, h.numero, h.tipo, h.precio_noche, h.estado,
       fn_IngresosTotalesHabitacion(h.id_habitacion) AS ingresos_historicos,
       (SELECT COUNT(*) FROM reservaciones r
        WHERE r.id_habitacion = h.id_habitacion
          AND r.estado NOT IN ('cancelada')) AS total_reservaciones
FROM habitaciones h;
/

CREATE OR REPLACE VIEW vw_PagosDetalle AS
SELECT p.id_pago, p.fecha_pago, p.monto, p.estado AS estado_pago,
       mp.nombre AS metodo_pago,
       u.nombre || ' ' || u.apellido_1 AS huesped,
       u.identificacion, h.numero AS habitacion,
       r.fecha_entrada, r.fecha_salida,
       f.id_factura, f.subtotal, f.impuesto, f.total AS total_factura
FROM pagos p
INNER JOIN reservaciones r ON p.id_reservacion = r.id_reservacion
INNER JOIN usuarios u ON r.id_usuario = u.id_usuario
INNER JOIN habitaciones h ON r.id_habitacion = h.id_habitacion
INNER JOIN metodos_pago mp ON p.id_metodo_pago = mp.id_metodo_pago
LEFT JOIN facturas f ON f.id_pago = p.id_pago;
/

CREATE OR REPLACE VIEW vw_VentasDetalle AS
SELECT v.id_venta, v.fecha_venta,
       u.nombre || ' ' || u.apellido_1 AS cliente,
       p.nombre AS producto, dv.cantidad,
       p.precio AS precio_unitario, dv.subtotal, v.total
FROM ventas v
INNER JOIN usuarios u ON v.id_usuario = u.id_usuario
INNER JOIN detalle_venta dv ON dv.id_venta = v.id_venta
INNER JOIN productos p ON dv.id_producto = p.id_producto;
/

CREATE OR REPLACE VIEW vw_UsuariosConRol AS
SELECT u.id_usuario, u.nombre, u.apellido_1, u.apellido_2,
       u.identificacion, u.correo, u.telefono, u.username,
       u.fecha_registro, r.nombre AS rol, r.descripcion AS descripcion_rol,
       fn_ReservacionesActivasUsuario(u.id_usuario) AS reservaciones_activas
FROM usuarios u
LEFT JOIN roles r ON u.id_rol = r.id_rol;
/

CREATE OR REPLACE VIEW vw_OfertasVigentes AS
SELECT id_oferta, titulo, descripcion, descuento,
       fecha_inicio, fecha_fin,
       (fecha_fin - TRUNC(SYSDATE)) AS dias_restantes
FROM ofertas
WHERE SYSDATE BETWEEN fecha_inicio AND fecha_fin;
/

CREATE OR REPLACE VIEW vw_IngresosPorMes AS
SELECT EXTRACT(YEAR FROM fecha_pago) AS anio,
       EXTRACT(MONTH FROM fecha_pago) AS mes,
       TO_CHAR(fecha_pago, 'Month') AS nombre_mes,
       COUNT(*) AS total_pagos,
       SUM(monto) AS ingresos_totales,
       ROUND(AVG(monto), 2) AS promedio_por_pago
FROM pagos
WHERE estado = 'completado'
GROUP BY EXTRACT(YEAR FROM fecha_pago),
         EXTRACT(MONTH FROM fecha_pago),
         TO_CHAR(fecha_pago, 'Month');
/

CREATE OR REPLACE VIEW vw_AuditoriaReservaciones AS
SELECT ar.id_auditoria, ar.id_reservacion,
       u.nombre || ' ' || u.apellido_1 AS huesped,
       h.numero AS habitacion,
       ar.estado_anterior, ar.estado_nuevo,
       ar.fecha_cambio, ar.usuario_sistema
FROM auditoria_reservaciones ar
LEFT JOIN reservaciones r ON ar.id_reservacion = r.id_reservacion
LEFT JOIN usuarios u ON r.id_usuario = u.id_usuario
LEFT JOIN habitaciones h ON r.id_habitacion = h.id_habitacion;
/

CREATE OR REPLACE VIEW vw_StockProductos AS
SELECT p.id_producto, p.nombre, p.descripcion, p.precio, p.stock,
       NVL(SUM(dv.cantidad), 0) AS total_vendido,
       CASE WHEN p.stock = 0   THEN 'Agotado'
            WHEN p.stock < 10  THEN 'Stock bajo'
            ELSE 'Disponible' END AS estado_stock
FROM productos p
LEFT JOIN detalle_venta dv ON dv.id_producto = p.id_producto
GROUP BY p.id_producto, p.nombre, p.descripcion, p.precio, p.stock;
/

CREATE OR REPLACE VIEW vw_Dashboard AS
SELECT
    (SELECT COUNT(*) FROM usuarios) AS total_usuarios,
    (SELECT COUNT(*) FROM habitaciones) AS total_habitaciones,
    (SELECT COUNT(*) FROM habitaciones WHERE estado = 'disponible') AS habitaciones_disponibles,
    (SELECT COUNT(*) FROM habitaciones WHERE estado = 'ocupada') AS habitaciones_ocupadas,
    (SELECT COUNT(*) FROM reservaciones WHERE estado NOT IN ('cancelada')) AS reservaciones_activas,
    (SELECT COUNT(*) FROM pagos WHERE estado = 'completado') AS total_pagos,
    (SELECT NVL(SUM(monto),0) FROM pagos WHERE estado = 'completado') AS ingresos_totales,
    fn_PorcentajeOcupacion() AS porcentaje_ocupacion
FROM DUAL;
/

-- =============================================
-- PASO 8: TRIGGERS (5 triggers)
-- =============================================

-- T1: Actualizar estado de habitacion segun reservaciones
CREATE OR REPLACE TRIGGER trg_ActualizarEstadoHabitacion
AFTER INSERT OR UPDATE ON reservaciones
FOR EACH ROW
BEGIN
    IF :NEW.estado = 'confirmada' THEN
        IF :NEW.fecha_entrada <= TRUNC(SYSDATE) AND :NEW.fecha_salida > TRUNC(SYSDATE) THEN
            UPDATE habitaciones SET estado = 'ocupada'
            WHERE id_habitacion = :NEW.id_habitacion;
        ELSIF :NEW.fecha_entrada > TRUNC(SYSDATE) THEN
            UPDATE habitaciones SET estado = 'reservada'
            WHERE id_habitacion = :NEW.id_habitacion;
        END IF;
    ELSIF :NEW.estado = 'cancelada' THEN
        UPDATE habitaciones SET estado = 'disponible'
        WHERE id_habitacion = :NEW.id_habitacion
          AND NOT EXISTS (
              SELECT 1 FROM reservaciones
              WHERE id_habitacion = :NEW.id_habitacion
                AND estado = 'confirmada'
                AND fecha_salida > TRUNC(SYSDATE)
                AND id_reservacion != :NEW.id_reservacion
          );
    END IF;
END;
/

-- T2: Auditoria de cambios de estado en reservaciones
CREATE OR REPLACE TRIGGER trg_AuditoriaReservaciones
AFTER UPDATE ON reservaciones
FOR EACH ROW
BEGIN
    IF :OLD.estado != :NEW.estado THEN
        INSERT INTO auditoria_reservaciones (id_reservacion, estado_anterior, estado_nuevo)
        VALUES (:NEW.id_reservacion, :OLD.estado, :NEW.estado);
    END IF;
END;
/

-- T3: Prevenir stock negativo
CREATE OR REPLACE TRIGGER trg_ValidarStock
BEFORE INSERT ON detalle_venta
FOR EACH ROW
DECLARE
    v_stock NUMBER;
BEGIN
    SELECT stock INTO v_stock FROM productos WHERE id_producto = :NEW.id_producto;
    IF v_stock < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20001, 'ERROR: Stock insuficiente para completar la venta');
    END IF;
END;
/

-- T4: Auditoria de creacion y eliminacion de usuarios
CREATE OR REPLACE TRIGGER trg_AuditoriaUsuarios
AFTER INSERT OR DELETE ON usuarios
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO auditoria_usuarios (id_usuario, accion)
        VALUES (:NEW.id_usuario, 'CREACION');
    ELSIF DELETING THEN
        INSERT INTO auditoria_usuarios (id_usuario, accion)
        VALUES (:OLD.id_usuario, 'ELIMINACION');
    END IF;
END;
/

-- T5: Actualizar total de venta automaticamente
CREATE OR REPLACE TRIGGER trg_ActualizarTotalVenta
AFTER INSERT OR UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE ventas
    SET total = (SELECT NVL(SUM(subtotal), 0) FROM detalle_venta WHERE id_venta = :NEW.id_venta)
    WHERE id_venta = :NEW.id_venta;
END;
/

COMMIT;

-- =============================================
-- RESUMEN FINAL
-- =============================================
-- Tablas:          15
-- Funciones:        8  (F1-F8)
-- Paquetes:         5  (PKG1-PKG5)
-- Procedimientos:   2  adicionales
-- Vistas:          10  (V1-V10)
-- Triggers:         5  (T1-T5)
-- =============================================

/* =================================================================
   SC-503 Administracion de Bases de Datos
   Carga de datos inicial (entre 50 y 150 registros por tabla)
   Hotel Altavista -- adaptado de Hotel Lenguaje (SC-504)

   REQUISITOS PREVIOS: ya deben existir, en este orden:
     1) El esquema exclusivo (01_esquema_usuarios_roles_perfiles_indices.sql,
        seccion 1)
     2) Las 16 tablas, vistas, paquetes, funciones y triggers
        (oracle_hotel_lenguaje.sql, ejecutado conectado como hotel_sc503)
     3) Perfiles, roles, usuarios e indices
        (01_esquema_usuarios_roles_perfiles_indices.sql, secciones 2-5)

   Ejecutar ESTE archivo conectado como hotel_sc503 (el dueno del esquema),
   con las tablas ya creadas pero vacias.
   ================================================================= */


-- =============================================
-- 1) ROLES (catalogo de puestos del hotel)
--    Las 3 primeras filas se preservan con id_rol = 1,2,3 porque el
--    codigo Java y los triggers ya asumen ese orden.
-- =============================================
INSERT INTO roles (nombre, descripcion) VALUES ('ADMIN', 'Administrador del sistema');
INSERT INTO roles (nombre, descripcion) VALUES ('RECEPCIONISTA', 'Personal de recepcion');
INSERT INTO roles (nombre, descripcion) VALUES ('CLIENTE', 'Cliente del hotel');

DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_tipos t_list := t_list('Administrador','Supervisor','Asistente','Especialista','Coordinador','Encargado');
  v_areas t_list := t_list('Recepcion','Reservas','Facturacion','Mantenimiento',
                            'Alimentos y Bebidas','Seguridad','Limpieza','Gerencia',
                            'Sistemas','Recursos Humanos','Marketing','Ventas',
                            'Auditoria Interna','Spa y Bienestar','Eventos');
BEGIN
  FOR t IN 1..v_tipos.COUNT LOOP
    FOR a IN 1..v_areas.COUNT LOOP
      INSERT INTO roles (nombre, descripcion)
      VALUES (UPPER(v_tipos(t) || '_' || REPLACE(v_areas(a), ' ', '_')),
              v_tipos(t) || ' de ' || v_areas(a));
    END LOOP;
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 2) METODOS_PAGO (metodo + entidad emisora)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_metodos t_list := t_list('Efectivo','Tarjeta de debito','Tarjeta de credito',
                              'Transferencia bancaria','SINPE Movil','Cheque',
                              'Criptomoneda','Cupon promocional');
  v_marcas  t_list := t_list('BAC Credomatic','Banco Nacional','Banco de Costa Rica',
                              'Scotiabank','Banco Popular','Davivienda','Promerica');
BEGIN
  FOR m IN 1..v_metodos.COUNT LOOP
    FOR b IN 1..v_marcas.COUNT LOOP
      INSERT INTO metodos_pago (nombre) VALUES (v_metodos(m) || ' - ' || v_marcas(b));
    END LOOP;
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 3) USUARIOS (100 filas: clientes, recepcionistas y administradores)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_nombres   t_list := t_list('Maria','Jose','Carlos','Ana','Luis','Sofia','Diego',
                                'Valeria','Andres','Camila','Fernando','Gabriela',
                                'Ricardo','Daniela','Esteban','Paola','Juan','Laura',
                                'Mario','Karla');
  v_apellidos t_list := t_list('Rodriguez','Mora','Jimenez','Vargas','Castro','Rojas',
                                'Solano','Chacon','Araya','Zuniga','Salas','Quesada',
                                'Fernandez','Brenes','Montero','Centeno','Figueroa',
                                'Saavedra','Gomez','Hernandez');
  v_rol_admin   NUMBER;
  v_rol_recep   NUMBER;
  v_rol_cliente NUMBER;
BEGIN
  SELECT id_rol INTO v_rol_admin   FROM roles WHERE nombre = 'ADMIN';
  SELECT id_rol INTO v_rol_recep   FROM roles WHERE nombre = 'RECEPCIONISTA';
  SELECT id_rol INTO v_rol_cliente FROM roles WHERE nombre = 'CLIENTE';

  FOR i IN 1..100 LOOP
    INSERT INTO usuarios (
      nombre, apellido_1, apellido_2, identificacion, correo, telefono,
      username, contrasena, fecha_registro, id_rol
    ) VALUES (
      v_nombres(MOD(i, v_nombres.COUNT) + 1),
      v_apellidos(MOD(i * 3, v_apellidos.COUNT) + 1),
      v_apellidos(MOD(i * 7, v_apellidos.COUNT) + 1),
      'ID' || LPAD(i, 9, '0'),
      LOWER(v_nombres(MOD(i, v_nombres.COUNT) + 1)) || '.' || i || '@correo.com',
      '8' || LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)), 7, '0'),
      LOWER(v_nombres(MOD(i, v_nombres.COUNT) + 1)) || i,
      '$2a$10$seedHashPlaceholder' || LPAD(i, 6, '0'),
      SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 730)),
      CASE
        WHEN MOD(i, 20) = 0 THEN v_rol_admin
        WHEN MOD(i, 4)  = 0 THEN v_rol_recep
        ELSE v_rol_cliente
      END
    );
  END LOOP;
  COMMIT;
END;
/
-- Nota: la contrasena es un valor de relleno (no es un hash BCrypt real).
-- Para probar login real desde la app, usar el usuario 'admin' creado
-- por el script original con su hash valido, o re-registrarse vía la UI.


-- =============================================
-- 4) HABITACIONES (100 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(30);
  v_tipos t_list := t_list('Individual','Doble','Suite','Familiar','Ejecutiva');
BEGIN
  FOR i IN 1..100 LOOP
    INSERT INTO habitaciones (numero, tipo, precio_noche, estado)
    VALUES (
      100 + i,
      v_tipos(MOD(i, v_tipos.COUNT) + 1),
      ROUND(DBMS_RANDOM.VALUE(35000, 180000), 2),
      'disponible'
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 5) OFERTAS (60 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_titulos t_list := t_list('Estadia larga','Temporada baja','Reserva anticipada',
                              'Fin de semana','Luna de miel','Corporativo',
                              'Dia festivo','Black Friday');
BEGIN
  FOR i IN 1..60 LOOP
    INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin)
    VALUES (
      v_titulos(MOD(i, v_titulos.COUNT) + 1) || ' #' || i,
      'Promocion generada para carga de datos de prueba',
      ROUND(DBMS_RANDOM.VALUE(5, 30), 2),
      SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 200)),
      SYSDATE + TRUNC(DBMS_RANDOM.VALUE(1, 200))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 6) PRODUCTOS (90 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_productos t_list := t_list('Agua mineral','Cafe','Snack mixto','Vino tinto',
                                'Servicio de lavanderia','Toalla blanca','Shampoo',
                                'Protector solar','Chocolate gourmet','Refresco',
                                'Cerveza artesanal','Almohada extra','Kit de bienvenida',
                                'Masaje express','Renta de bicicleta');
BEGIN
  FOR i IN 1..90 LOOP
    INSERT INTO productos (nombre, descripcion, precio, stock)
    VALUES (
      v_productos(MOD(i, v_productos.COUNT) + 1) || ' ' || i,
      'Producto/servicio de hotel generado para pruebas',
      ROUND(DBMS_RANDOM.VALUE(1000, 25000), 2),
      TRUNC(DBMS_RANDOM.VALUE(20, 200))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 7) RESERVACIONES (150 filas)
--    Dispara trg_ActualizarEstadoHabitacion automaticamente.
-- =============================================
DECLARE
  v_max_usuario    NUMBER;
  v_max_habitacion NUMBER;
  v_max_oferta     NUMBER;
  v_entrada        DATE;
  v_noches         NUMBER;
  v_estado         VARCHAR2(20);
  v_precio_noche   NUMBER(10,2);
  v_descuento      NUMBER(5,2);
  v_id_oferta      NUMBER;
  v_id_habitacion  NUMBER;
  v_total          NUMBER(10,2);
BEGIN
  SELECT MAX(id_usuario)    INTO v_max_usuario    FROM usuarios;
  SELECT MAX(id_habitacion) INTO v_max_habitacion FROM habitaciones;
  SELECT MAX(id_oferta)     INTO v_max_oferta     FROM ofertas;

  FOR i IN 1..150 LOOP
    v_entrada       := DATE '2026-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 300));
    v_noches        := TRUNC(DBMS_RANDOM.VALUE(1, 10));
    v_id_habitacion := TRUNC(DBMS_RANDOM.VALUE(1, v_max_habitacion + 1));
    v_estado        := CASE MOD(i, 4)
                          WHEN 0 THEN 'pendiente'
                          WHEN 1 THEN 'confirmada'
                          WHEN 2 THEN 'pagada'
                          ELSE 'cancelada'
                        END;

    SELECT precio_noche INTO v_precio_noche FROM habitaciones WHERE id_habitacion = v_id_habitacion;

    IF MOD(i, 3) = 0 THEN
      v_id_oferta := TRUNC(DBMS_RANDOM.VALUE(1, v_max_oferta + 1));
      SELECT descuento INTO v_descuento FROM ofertas WHERE id_oferta = v_id_oferta;
    ELSE
      v_id_oferta := NULL;
      v_descuento := 0;
    END IF;

    v_total := ROUND(v_precio_noche * v_noches * (1 - v_descuento / 100), 2);

    INSERT INTO reservaciones (
      fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion, id_oferta
    ) VALUES (
      v_entrada, v_entrada + v_noches, v_estado, v_total,
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_usuario + 1)), v_id_habitacion, v_id_oferta
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 8) PAGOS (150 filas)
-- =============================================
DECLARE
  v_max_reserv NUMBER;
  v_max_metodo NUMBER;
BEGIN
  SELECT MAX(id_reservacion) INTO v_max_reserv FROM reservaciones;
  SELECT MAX(id_metodo_pago) INTO v_max_metodo FROM metodos_pago;

  FOR i IN 1..150 LOOP
    INSERT INTO pagos (fecha_pago, monto, estado, id_reservacion, id_metodo_pago)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      ROUND(DBMS_RANDOM.VALUE(20000, 900000), 2),
      CASE MOD(i, 3) WHEN 0 THEN 'pendiente' ELSE 'completado' END,
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_reserv + 1)),
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_metodo + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 9) FACTURAS (100 filas)
-- =============================================
DECLARE
  v_max_pago NUMBER;
  v_subtotal NUMBER(10,2);
  v_impuesto NUMBER(10,2);
BEGIN
  SELECT MAX(id_pago) INTO v_max_pago FROM pagos;
  FOR i IN 1..100 LOOP
    v_subtotal := ROUND(DBMS_RANDOM.VALUE(20000, 900000), 2);
    v_impuesto := ROUND(v_subtotal * 0.13, 2);
    INSERT INTO facturas (fecha_emision, subtotal, impuesto, total, id_pago)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      v_subtotal, v_impuesto, v_subtotal + v_impuesto,
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_pago + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 10) CARGOS_EXTRA (100 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_desc t_list := t_list('Consumo de minibar','Servicio a la habitacion',
                           'Lavanderia express','Renta de toallas','Estacionamiento',
                           'Spa','Transporte al aeropuerto','Desayuno adicional');
  v_max_reserv NUMBER;
BEGIN
  SELECT MAX(id_reservacion) INTO v_max_reserv FROM reservaciones;
  FOR i IN 1..100 LOOP
    INSERT INTO cargos_extra (descripcion, monto, id_reservacion)
    VALUES (
      v_desc(MOD(i, v_desc.COUNT) + 1),
      ROUND(DBMS_RANDOM.VALUE(2000, 45000), 2),
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_reserv + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 11) REEMBOLSOS (60 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(60);
  v_motivos t_list := t_list('Cancelacion de reservacion','Error en el cobro',
                              'Cambio de fechas','Insatisfaccion del huesped','Overbooking');
  v_max_pago NUMBER;
BEGIN
  SELECT MAX(id_pago) INTO v_max_pago FROM pagos;
  FOR i IN 1..60 LOOP
    INSERT INTO reembolsos (fecha_reembolso, monto, motivo, id_pago)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      ROUND(DBMS_RANDOM.VALUE(5000, 300000), 2),
      v_motivos(MOD(i, v_motivos.COUNT) + 1),
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_pago + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 12) VENTAS (100 filas) -- total en 0, lo recalcula trg_ActualizarTotalVenta
-- =============================================
DECLARE
  v_max_usuario NUMBER;
BEGIN
  SELECT MAX(id_usuario) INTO v_max_usuario FROM usuarios;
  FOR i IN 1..100 LOOP
    INSERT INTO ventas (fecha_venta, total, id_usuario)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      0,
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_usuario + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 13) DETALLE_VENTA (150 filas)
--     La cantidad respeta el stock para no disparar trg_ValidarStock.
--     Cada insert dispara trg_ActualizarTotalVenta, que recalcula ventas.total.
-- =============================================
DECLARE
  v_max_venta    NUMBER;
  v_max_producto NUMBER;
  v_id_producto  NUMBER;
  v_stock        NUMBER;
  v_precio       NUMBER(10,2);
  v_cantidad     NUMBER;
BEGIN
  SELECT MAX(id_venta)    INTO v_max_venta    FROM ventas;
  SELECT MAX(id_producto) INTO v_max_producto FROM productos;

  FOR i IN 1..150 LOOP
    v_id_producto := TRUNC(DBMS_RANDOM.VALUE(1, v_max_producto + 1));
    SELECT stock, precio INTO v_stock, v_precio FROM productos WHERE id_producto = v_id_producto;
    v_cantidad := TRUNC(DBMS_RANDOM.VALUE(1, LEAST(v_stock, 5) + 1));

    INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal)
    VALUES (
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_venta + 1)),
      v_id_producto,
      v_cantidad,
      ROUND(v_precio * v_cantidad, 2)
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 14) LOGIN_AUDITORIA (100 filas)
-- =============================================
DECLARE
  v_max_usuario NUMBER;
BEGIN
  SELECT MAX(id_usuario) INTO v_max_usuario FROM usuarios;
  FOR i IN 1..100 LOOP
    INSERT INTO login_auditoria (ip, fecha_login, dispositivo, id_usuario)
    VALUES (
      TRUNC(DBMS_RANDOM.VALUE(1,255)) || '.' || TRUNC(DBMS_RANDOM.VALUE(1,255)) || '.' ||
      TRUNC(DBMS_RANDOM.VALUE(1,255)) || '.' || TRUNC(DBMS_RANDOM.VALUE(1,255)),
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      CASE MOD(i, 3)
        WHEN 0 THEN 'Chrome - Windows'
        WHEN 1 THEN 'Safari - iPhone'
        ELSE 'Firefox - Android'
      END,
      TRUNC(DBMS_RANDOM.VALUE(1, v_max_usuario + 1))
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 15) AUDITORIA_RESERVACIONES -- se llena SOLA via trg_AuditoriaReservaciones
--     al hacer estos UPDATE (cada cambio real de estado = 1 fila de auditoria)
-- =============================================
UPDATE reservaciones SET estado = 'confirmada' WHERE estado = 'pendiente';
UPDATE reservaciones SET estado = 'pagada'     WHERE estado = 'confirmada' AND MOD(id_reservacion, 2) = 0;
UPDATE reservaciones SET estado = 'cancelada'  WHERE estado = 'pagada'     AND MOD(id_reservacion, 4) = 0;
COMMIT;

-- Nota: AUDITORIA_USUARIOS tambien se llena sola: trg_AuditoriaUsuarios ya
-- genero ~100 filas 'CREACION' en el paso 3 (usuarios), una por cada INSERT.


-- =============================================
-- 16) VERIFICACION: conteo de filas por tabla (debe estar entre 50 y 150,
--     salvo lo que el profesor confirme como catalogo de valor fijo)
-- =============================================
SELECT 'roles' AS tabla, COUNT(*) AS filas FROM roles
UNION ALL SELECT 'usuarios',                COUNT(*) FROM usuarios
UNION ALL SELECT 'habitaciones',            COUNT(*) FROM habitaciones
UNION ALL SELECT 'ofertas',                 COUNT(*) FROM ofertas
UNION ALL SELECT 'reservaciones',           COUNT(*) FROM reservaciones
UNION ALL SELECT 'metodos_pago',            COUNT(*) FROM metodos_pago
UNION ALL SELECT 'pagos',                   COUNT(*) FROM pagos
UNION ALL SELECT 'facturas',                COUNT(*) FROM facturas
UNION ALL SELECT 'cargos_extra',            COUNT(*) FROM cargos_extra
UNION ALL SELECT 'reembolsos',              COUNT(*) FROM reembolsos
UNION ALL SELECT 'productos',               COUNT(*) FROM productos
UNION ALL SELECT 'ventas',                  COUNT(*) FROM ventas
UNION ALL SELECT 'detalle_venta',           COUNT(*) FROM detalle_venta
UNION ALL SELECT 'login_auditoria',         COUNT(*) FROM login_auditoria
UNION ALL SELECT 'auditoria_reservaciones', COUNT(*) FROM auditoria_reservaciones
UNION ALL SELECT 'auditoria_usuarios',      COUNT(*) FROM auditoria_usuarios
ORDER BY 1;

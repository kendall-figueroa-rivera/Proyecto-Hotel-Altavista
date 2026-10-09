/* =================================================================
   SC-503 Administracion de Bases de Datos -- VERSION 2 (corregida)
   Carga de datos inicial (entre 50 y 150 registros por tabla)
   Hotel Altavista

   Que cambio respecto a la v1:
   - Se limpia (TRUNCATE) todo lo que quedo a medias o duplicado
     por los errores anteriores, para partir de cero.
   - Se corrige el error PLS-00425: antes se llamaba v_lista(MOD(i,
     v_lista.COUNT)+1) directo dentro del INSERT, y Oracle no permite
     mezclar el metodo .COUNT de una coleccion dentro de una sentencia
     SQL. Ahora cada valor se calcula primero en una variable normal,
     y el INSERT solo usa esa variable.
   - Ya no se vuelve a insertar ADMIN/RECEPCIONISTA/CLIENTE (duplicaba
     esos 3 roles); se toman sus id_rol existentes.
   - Se preserva el usuario real de prueba admin/admin123 que ya tenia
     el proyecto, para poder seguir usando ese login en la app.
   - Las reservaciones ya no nacen con estado 'cancelada' (eso ahora
     solo pasa por UPDATE, igual que en la aplicacion real); el bug
     de tabla mutante en los triggers debe estar corregido ANTES de
     correr este script (ver 03_fix_triggers_mutantes.sql).

   ORDEN: 1) correr 03_fix_triggers_mutantes.sql
          2) correr este archivo completo, conectado como admin_hotel
   ================================================================= */


-- =============================================
-- 0) LIMPIEZA: borra todo para partir de cero (orden hijo -> padre)
--    Se usa DELETE y no TRUNCATE: Oracle no permite truncar una tabla
--    si otra tabla tiene una FK habilitada apuntando hacia ella, aunque
--    esa otra ya este vacia (ORA-02266). DELETE no tiene esa restriccion.
--
--    IMPORTANTE: el servicio "_high" de Autonomous Database activa DML
--    en paralelo por defecto, y eso choca con hacer varios DELETE sobre
--    tablas relacionadas en la misma transaccion (ORA-12839). Por eso
--    se desactiva el paralelismo de DML antes de empezar, y se hace
--    COMMIT despues de cada DELETE para no dejar nada a medias si algo
--    mas llegara a fallar.
--
--    Nota: los contadores IDENTITY no se reinician con DELETE (los IDs
--    nuevos van a seguir subiendo desde donde iban) -- eso no afecta
--    nada funcional, solo que no van a empezar de nuevo en 1.
-- =============================================
ALTER SESSION DISABLE PARALLEL DML;

DELETE FROM auditoria_usuarios;        COMMIT;
DELETE FROM auditoria_reservaciones;   COMMIT;
DELETE FROM login_auditoria;           COMMIT;
DELETE FROM detalle_venta;             COMMIT;
DELETE FROM ventas;                    COMMIT;
DELETE FROM reembolsos;                COMMIT;
DELETE FROM cargos_extra;              COMMIT;
DELETE FROM facturas;                  COMMIT;
DELETE FROM pagos;                     COMMIT;
DELETE FROM reservaciones;             COMMIT;
DELETE FROM productos;                 COMMIT;
DELETE FROM ofertas;                   COMMIT;
DELETE FROM habitaciones;              COMMIT;
DELETE FROM metodos_pago;              COMMIT;
DELETE FROM usuarios;                  COMMIT;
DELETE FROM roles;                     COMMIT;


-- =============================================
-- 1) ROLES (catalogo de puestos del hotel)
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
  v_nombre_rol VARCHAR2(120);
  v_desc_rol   VARCHAR2(120);
BEGIN
  FOR t IN 1..v_tipos.COUNT LOOP
    FOR a IN 1..v_areas.COUNT LOOP
      v_nombre_rol := UPPER(v_tipos(t) || '_' || REPLACE(v_areas(a), ' ', '_'));
      v_desc_rol   := v_tipos(t) || ' de ' || v_areas(a);
      INSERT INTO roles (nombre, descripcion) VALUES (v_nombre_rol, v_desc_rol);
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
  v_nombre VARCHAR2(120);
BEGIN
  FOR m IN 1..v_metodos.COUNT LOOP
    FOR b IN 1..v_marcas.COUNT LOOP
      v_nombre := v_metodos(m) || ' - ' || v_marcas(b);
      INSERT INTO metodos_pago (nombre) VALUES (v_nombre);
    END LOOP;
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 3) USUARIOS (1 usuario real de prueba + 99 generados = 100 filas)
-- =============================================

-- Usuario real para poder iniciar sesion en la app (contrasena: admin123)
INSERT INTO usuarios (nombre, apellido_1, apellido_2, identificacion, correo, telefono, username, contrasena, fecha_registro, id_rol)
VALUES ('Admin', 'Hotel', 'Sistema', '000000001', 'admin@hotel.com', '88888888', 'admin',
        '$2a$10$slYQmyNdgTY18LGvgxPwsOWGMNGGnBbZDrivuOYTl36G4bFTIIGWS', SYSDATE,
        (SELECT MIN(id_rol) FROM roles WHERE nombre = 'ADMIN'));

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
  v_nombre      VARCHAR2(60);
  v_apellido1   VARCHAR2(60);
  v_apellido2   VARCHAR2(60);
  v_id_rol      NUMBER;
BEGIN
  SELECT MIN(id_rol) INTO v_rol_admin   FROM roles WHERE nombre = 'ADMIN';
  SELECT MIN(id_rol) INTO v_rol_recep   FROM roles WHERE nombre = 'RECEPCIONISTA';
  SELECT MIN(id_rol) INTO v_rol_cliente FROM roles WHERE nombre = 'CLIENTE';

  FOR i IN 1..99 LOOP
    v_nombre    := v_nombres(MOD(i, v_nombres.COUNT) + 1);
    v_apellido1 := v_apellidos(MOD(i * 3, v_apellidos.COUNT) + 1);
    v_apellido2 := v_apellidos(MOD(i * 7, v_apellidos.COUNT) + 1);
    v_id_rol    := CASE
                     WHEN MOD(i, 20) = 0 THEN v_rol_admin
                     WHEN MOD(i, 4)  = 0 THEN v_rol_recep
                     ELSE v_rol_cliente
                   END;

    INSERT INTO usuarios (
      nombre, apellido_1, apellido_2, identificacion, correo, telefono,
      username, contrasena, fecha_registro, id_rol
    ) VALUES (
      v_nombre, v_apellido1, v_apellido2,
      'ID' || LPAD(i, 9, '0'),
      LOWER(v_nombre) || '.' || i || '@correo.com',
      '8' || LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)), 7, '0'),
      LOWER(v_nombre) || i,
      '$2a$10$seedHashPlaceholder' || LPAD(i, 6, '0'),
      SYSDATE - TRUNC(DBMS_RANDOM.VALUE(1, 730)),
      v_id_rol
    );
  END LOOP;
  COMMIT;
END;
/
-- Nota: solo el usuario 'admin' tiene una contrasena real (admin123).
-- Los otros 99 tienen un valor de relleno, no sirven para iniciar sesion.


-- =============================================
-- 4) HABITACIONES (100 filas)
-- =============================================
DECLARE
  TYPE t_list IS TABLE OF VARCHAR2(30);
  v_tipos t_list := t_list('Individual','Doble','Suite','Familiar','Ejecutiva');
  v_tipo VARCHAR2(30);
BEGIN
  FOR i IN 1..100 LOOP
    v_tipo := v_tipos(MOD(i, v_tipos.COUNT) + 1);
    INSERT INTO habitaciones (numero, tipo, precio_noche, estado)
    VALUES (100 + i, v_tipo, ROUND(DBMS_RANDOM.VALUE(35000, 180000), 2), 'disponible');
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
  v_titulo VARCHAR2(80);
BEGIN
  FOR i IN 1..60 LOOP
    v_titulo := v_titulos(MOD(i, v_titulos.COUNT) + 1) || ' #' || i;
    INSERT INTO ofertas (titulo, descripcion, descuento, fecha_inicio, fecha_fin)
    VALUES (
      v_titulo,
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
  v_nombre VARCHAR2(80);
BEGIN
  FOR i IN 1..90 LOOP
    v_nombre := v_productos(MOD(i, v_productos.COUNT) + 1) || ' ' || i;
    INSERT INTO productos (nombre, descripcion, precio, stock)
    VALUES (v_nombre, 'Producto/servicio de hotel generado para pruebas',
            ROUND(DBMS_RANDOM.VALUE(1000, 25000), 2), TRUNC(DBMS_RANDOM.VALUE(20, 200)));
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 7) RESERVACIONES (150 filas) -- sin 'cancelada' al nacer,
--    eso se genera despues via UPDATE (paso 15)
--
--    IMPORTANTE: como DELETE no reinicia los contadores IDENTITY, los
--    IDs existentes pueden tener "huecos" (no son 1,2,3... consecutivos
--    si ya se corrio este script antes). Por eso aqui se traen los IDs
--    que SI existen con BULK COLLECT, y se elige al azar de esa lista
--    -- nunca se "adivina" un ID entre 1 y el maximo.
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_usuarios_ids     t_num_list;
  v_habitaciones_ids t_num_list;
  v_ofertas_ids      t_num_list;
  v_entrada        DATE;
  v_noches         NUMBER;
  v_estado         VARCHAR2(20);
  v_precio_noche   NUMBER(10,2);
  v_descuento      NUMBER(5,2);
  v_id_oferta      NUMBER;
  v_id_habitacion  NUMBER;
  v_id_usuario     NUMBER;
  v_total          NUMBER(10,2);
BEGIN
  SELECT id_usuario    BULK COLLECT INTO v_usuarios_ids     FROM usuarios;
  SELECT id_habitacion BULK COLLECT INTO v_habitaciones_ids FROM habitaciones;
  SELECT id_oferta     BULK COLLECT INTO v_ofertas_ids      FROM ofertas;

  FOR i IN 1..150 LOOP
    v_entrada       := DATE '2026-01-01' + TRUNC(DBMS_RANDOM.VALUE(0, 300));
    v_noches        := TRUNC(DBMS_RANDOM.VALUE(1, 10));
    v_id_habitacion := v_habitaciones_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_habitaciones_ids.COUNT + 1)));
    v_id_usuario    := v_usuarios_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_usuarios_ids.COUNT + 1)));
    v_estado        := CASE MOD(i, 3)
                          WHEN 0 THEN 'pendiente'
                          WHEN 1 THEN 'confirmada'
                          ELSE 'pagada'
                        END;

    SELECT precio_noche INTO v_precio_noche FROM habitaciones WHERE id_habitacion = v_id_habitacion;

    IF MOD(i, 3) = 0 THEN
      v_id_oferta := v_ofertas_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_ofertas_ids.COUNT + 1)));
      SELECT descuento INTO v_descuento FROM ofertas WHERE id_oferta = v_id_oferta;
    ELSE
      v_id_oferta := NULL;
      v_descuento := 0;
    END IF;

    v_total := ROUND(v_precio_noche * v_noches * (1 - v_descuento / 100), 2);

    INSERT INTO reservaciones (
      fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion, id_oferta
    ) VALUES (
      v_entrada, v_entrada + v_noches, v_estado, v_total, v_id_usuario, v_id_habitacion, v_id_oferta
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 8) PAGOS (150 filas)
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_reserv_ids t_num_list;
  v_metodo_ids t_num_list;
  v_id_reserv  NUMBER;
  v_id_metodo  NUMBER;
BEGIN
  SELECT id_reservacion BULK COLLECT INTO v_reserv_ids FROM reservaciones;
  SELECT id_metodo_pago BULK COLLECT INTO v_metodo_ids FROM metodos_pago;

  FOR i IN 1..150 LOOP
    v_id_reserv := v_reserv_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_reserv_ids.COUNT + 1)));
    v_id_metodo := v_metodo_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_metodo_ids.COUNT + 1)));

    INSERT INTO pagos (fecha_pago, monto, estado, id_reservacion, id_metodo_pago)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      ROUND(DBMS_RANDOM.VALUE(20000, 900000), 2),
      CASE MOD(i, 3) WHEN 0 THEN 'pendiente' ELSE 'completado' END,
      v_id_reserv, v_id_metodo
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 9) FACTURAS (100 filas)
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_pago_ids t_num_list;
  v_id_pago  NUMBER;
  v_subtotal NUMBER(10,2);
  v_impuesto NUMBER(10,2);
BEGIN
  SELECT id_pago BULK COLLECT INTO v_pago_ids FROM pagos;
  FOR i IN 1..100 LOOP
    v_id_pago  := v_pago_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_pago_ids.COUNT + 1)));
    v_subtotal := ROUND(DBMS_RANDOM.VALUE(20000, 900000), 2);
    v_impuesto := ROUND(v_subtotal * 0.13, 2);
    INSERT INTO facturas (fecha_emision, subtotal, impuesto, total, id_pago)
    VALUES (
      SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
      v_subtotal, v_impuesto, v_subtotal + v_impuesto, v_id_pago
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
  TYPE t_num_list IS TABLE OF NUMBER;
  v_reserv_ids  t_num_list;
  v_id_reserv   NUMBER;
  v_descripcion VARCHAR2(80);
BEGIN
  SELECT id_reservacion BULK COLLECT INTO v_reserv_ids FROM reservaciones;
  FOR i IN 1..100 LOOP
    v_descripcion := v_desc(MOD(i, v_desc.COUNT) + 1);
    v_id_reserv   := v_reserv_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_reserv_ids.COUNT + 1)));
    INSERT INTO cargos_extra (descripcion, monto, id_reservacion)
    VALUES (v_descripcion, ROUND(DBMS_RANDOM.VALUE(2000, 45000), 2), v_id_reserv);
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
  TYPE t_num_list IS TABLE OF NUMBER;
  v_pago_ids t_num_list;
  v_id_pago  NUMBER;
  v_motivo   VARCHAR2(80);
BEGIN
  SELECT id_pago BULK COLLECT INTO v_pago_ids FROM pagos;
  FOR i IN 1..60 LOOP
    v_motivo  := v_motivos(MOD(i, v_motivos.COUNT) + 1);
    v_id_pago := v_pago_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_pago_ids.COUNT + 1)));
    INSERT INTO reembolsos (fecha_reembolso, monto, motivo, id_pago)
    VALUES (SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)),
            ROUND(DBMS_RANDOM.VALUE(5000, 300000), 2), v_motivo, v_id_pago);
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 12) VENTAS (100 filas) -- total en 0, lo recalcula el trigger ya corregido
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_usuarios_ids t_num_list;
  v_id_usuario   NUMBER;
BEGIN
  SELECT id_usuario BULK COLLECT INTO v_usuarios_ids FROM usuarios;
  FOR i IN 1..100 LOOP
    v_id_usuario := v_usuarios_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_usuarios_ids.COUNT + 1)));
    INSERT INTO ventas (fecha_venta, total, id_usuario)
    VALUES (SYSTIMESTAMP - TRUNC(DBMS_RANDOM.VALUE(0, 300)), 0, v_id_usuario);
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 13) DETALLE_VENTA (150 filas)
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_venta_ids    t_num_list;
  v_producto_ids t_num_list;
  v_id_venta     NUMBER;
  v_id_producto  NUMBER;
  v_stock        NUMBER;
  v_precio       NUMBER(10,2);
  v_cantidad     NUMBER;
BEGIN
  SELECT id_venta    BULK COLLECT INTO v_venta_ids    FROM ventas;
  SELECT id_producto BULK COLLECT INTO v_producto_ids FROM productos;

  FOR i IN 1..150 LOOP
    v_id_venta    := v_venta_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_venta_ids.COUNT + 1)));
    v_id_producto := v_producto_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_producto_ids.COUNT + 1)));
    SELECT stock, precio INTO v_stock, v_precio FROM productos WHERE id_producto = v_id_producto;
    v_cantidad := TRUNC(DBMS_RANDOM.VALUE(1, LEAST(v_stock, 5) + 1));

    INSERT INTO detalle_venta (id_venta, id_producto, cantidad, subtotal)
    VALUES (v_id_venta, v_id_producto, v_cantidad, ROUND(v_precio * v_cantidad, 2));
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 14) LOGIN_AUDITORIA (100 filas)
-- =============================================
DECLARE
  TYPE t_num_list IS TABLE OF NUMBER;
  v_usuarios_ids t_num_list;
  v_id_usuario   NUMBER;
BEGIN
  SELECT id_usuario BULK COLLECT INTO v_usuarios_ids FROM usuarios;
  FOR i IN 1..100 LOOP
    v_id_usuario := v_usuarios_ids(TRUNC(DBMS_RANDOM.VALUE(1, v_usuarios_ids.COUNT + 1)));
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
      v_id_usuario
    );
  END LOOP;
  COMMIT;
END;
/


-- =============================================
-- 15) AUDITORIA_RESERVACIONES -- se llena SOLA via el trigger (ya corregido)
-- =============================================
UPDATE reservaciones SET estado = 'confirmada' WHERE estado = 'pendiente';
UPDATE reservaciones SET estado = 'pagada'     WHERE estado = 'confirmada' AND MOD(id_reservacion, 2) = 0;
UPDATE reservaciones SET estado = 'cancelada'  WHERE estado = 'pagada'     AND MOD(id_reservacion, 4) = 0;
COMMIT;

-- auditoria_usuarios tambien se llena sola (trg_AuditoriaUsuarios) con
-- cada INSERT de usuarios de arriba.


-- =============================================
-- 16) VERIFICACION: conteo de filas por tabla
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

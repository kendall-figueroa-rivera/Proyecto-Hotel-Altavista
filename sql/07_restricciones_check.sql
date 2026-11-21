/* =================================================================
   SC-503 Administracion de Bases de Datos
   Hotel Altavista -- Restricciones CHECK de integridad de dominio
   (observacion del profesor en el Avance 1)

   Ejecutar conectado como ADMIN_HOTEL (dueno de las tablas).
   No toca datos, grants, indices ni sinonimos: solo agrega reglas.

   Los valores permitidos salen de lo que la aplicacion usa de verdad
   (paquetes, triggers, codigo Java y formularios), para no romperla.
   ================================================================= */


/* =================================================================
   PASO 1: PRE-CHEQUEO
   Cada fila debe dar 0. Si alguna da mayor que 0, hay datos que
   violan esa regla y el ALTER TABLE del paso 2 fallaria con
   ORA-02293. En ese caso se corrige el dato antes de continuar.
   ================================================================= */
SELECT 'habitaciones: precio_noche <= 0' AS regla, COUNT(*) AS violaciones FROM habitaciones WHERE precio_noche <= 0
UNION ALL SELECT 'habitaciones: numero <= 0',            COUNT(*) FROM habitaciones   WHERE numero <= 0
UNION ALL SELECT 'habitaciones: tipo fuera de dominio',  COUNT(*) FROM habitaciones   WHERE LOWER(tipo) NOT IN ('individual','doble','suite','familiar','ejecutiva')
UNION ALL SELECT 'habitaciones: estado fuera de dominio',COUNT(*) FROM habitaciones   WHERE estado NOT IN ('disponible','ocupada','reservada','mantenimiento')
UNION ALL SELECT 'ofertas: descuento fuera de 0-100',    COUNT(*) FROM ofertas        WHERE descuento < 0 OR descuento > 100
UNION ALL SELECT 'ofertas: fecha_fin < fecha_inicio',    COUNT(*) FROM ofertas        WHERE fecha_fin < fecha_inicio
UNION ALL SELECT 'reservaciones: salida <= entrada',     COUNT(*) FROM reservaciones  WHERE fecha_salida <= fecha_entrada
UNION ALL SELECT 'reservaciones: estado fuera de dominio',COUNT(*) FROM reservaciones WHERE estado NOT IN ('pendiente','confirmada','pagada','cancelada','finalizada')
UNION ALL SELECT 'reservaciones: total_pago < 0',        COUNT(*) FROM reservaciones  WHERE total_pago < 0
UNION ALL SELECT 'pagos: monto <= 0',                    COUNT(*) FROM pagos          WHERE monto <= 0
UNION ALL SELECT 'pagos: estado fuera de dominio',       COUNT(*) FROM pagos          WHERE estado NOT IN ('pendiente','completado','reembolsado')
UNION ALL SELECT 'facturas: montos negativos',           COUNT(*) FROM facturas       WHERE subtotal < 0 OR impuesto < 0 OR total < 0
UNION ALL SELECT 'cargos_extra: monto <= 0',             COUNT(*) FROM cargos_extra   WHERE monto <= 0
UNION ALL SELECT 'reembolsos: monto <= 0',               COUNT(*) FROM reembolsos     WHERE monto <= 0
UNION ALL SELECT 'productos: precio < 0 o stock < 0',    COUNT(*) FROM productos      WHERE precio < 0 OR stock < 0
UNION ALL SELECT 'ventas: total < 0',                    COUNT(*) FROM ventas         WHERE total < 0
UNION ALL SELECT 'detalle_venta: cantidad<=0 o subtotal<0', COUNT(*) FROM detalle_venta WHERE cantidad <= 0 OR subtotal < 0
UNION ALL SELECT 'usuarios: correo sin formato valido',  COUNT(*) FROM usuarios       WHERE correo NOT LIKE '%_@_%._%';


/* =================================================================
   PASO 2: RESTRICCIONES CHECK
   ================================================================= */

-- habitaciones
ALTER TABLE habitaciones ADD CONSTRAINT ck_habitaciones_numero
  CHECK (numero > 0);
ALTER TABLE habitaciones ADD CONSTRAINT ck_habitaciones_precio
  CHECK (precio_noche > 0);
ALTER TABLE habitaciones ADD CONSTRAINT ck_habitaciones_tipo
  CHECK (LOWER(tipo) IN ('individual','doble','suite','familiar','ejecutiva'));
ALTER TABLE habitaciones ADD CONSTRAINT ck_habitaciones_estado
  CHECK (estado IN ('disponible','ocupada','reservada','mantenimiento'));

-- ofertas
ALTER TABLE ofertas ADD CONSTRAINT ck_ofertas_descuento
  CHECK (descuento >= 0 AND descuento <= 100);
ALTER TABLE ofertas ADD CONSTRAINT ck_ofertas_fechas
  CHECK (fecha_fin >= fecha_inicio);

-- reservaciones
ALTER TABLE reservaciones ADD CONSTRAINT ck_reservaciones_fechas
  CHECK (fecha_salida > fecha_entrada);
ALTER TABLE reservaciones ADD CONSTRAINT ck_reservaciones_estado
  CHECK (estado IN ('pendiente','confirmada','pagada','cancelada','finalizada'));
ALTER TABLE reservaciones ADD CONSTRAINT ck_reservaciones_total
  CHECK (total_pago >= 0);

-- pagos
ALTER TABLE pagos ADD CONSTRAINT ck_pagos_monto
  CHECK (monto > 0);
ALTER TABLE pagos ADD CONSTRAINT ck_pagos_estado
  CHECK (estado IN ('pendiente','completado','reembolsado'));

-- facturas
ALTER TABLE facturas ADD CONSTRAINT ck_facturas_montos
  CHECK (subtotal >= 0 AND impuesto >= 0 AND total >= 0);

-- cargos_extra y reembolsos
ALTER TABLE cargos_extra ADD CONSTRAINT ck_cargos_monto
  CHECK (monto > 0);
ALTER TABLE reembolsos ADD CONSTRAINT ck_reembolsos_monto
  CHECK (monto > 0);

-- productos
ALTER TABLE productos ADD CONSTRAINT ck_productos_precio
  CHECK (precio >= 0);
ALTER TABLE productos ADD CONSTRAINT ck_productos_stock
  CHECK (stock >= 0);

-- ventas y detalle_venta
ALTER TABLE ventas ADD CONSTRAINT ck_ventas_total
  CHECK (total >= 0);
ALTER TABLE detalle_venta ADD CONSTRAINT ck_detalle_cantidad
  CHECK (cantidad > 0);
ALTER TABLE detalle_venta ADD CONSTRAINT ck_detalle_subtotal
  CHECK (subtotal >= 0);

-- usuarios (formato minimo de correo)
ALTER TABLE usuarios ADD CONSTRAINT ck_usuarios_correo
  CHECK (correo LIKE '%_@_%._%');


/* =================================================================
   PASO 3: VERIFICACION -- lista las restricciones CHECK creadas
   (sirve como evidencia para el informe)
   ================================================================= */
SELECT table_name, constraint_name, search_condition_vc AS condicion, status
FROM   user_constraints
WHERE  constraint_type = 'C'
  AND  constraint_name LIKE 'CK\_%' ESCAPE '\'
ORDER  BY table_name, constraint_name;


/* =================================================================
   PASO 4 (OPCIONAL): PRUEBAS NEGATIVAS PARA EVIDENCIA
   Cada una debe fallar con ORA-02290 (check constraint violated).
   Correr de una en una y tomar captura del error; no dejan datos
   porque Oracle rechaza la fila.
   ================================================================= */
-- Precio de habitacion negativo
-- INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (9001, 'Doble', -5000, 'disponible');

-- Estado inexistente
-- INSERT INTO habitaciones (numero, tipo, precio_noche, estado) VALUES (9002, 'Doble', 50000, 'volando');

-- Descuento mayor a 100 %
-- INSERT INTO ofertas (titulo, descuento, fecha_inicio, fecha_fin) VALUES ('Prueba', 150, SYSDATE, SYSDATE + 5);

-- Salida antes de la entrada
-- INSERT INTO reservaciones (fecha_entrada, fecha_salida, estado, total_pago, id_usuario, id_habitacion)
-- VALUES (DATE '2026-12-10', DATE '2026-12-05', 'confirmada', 1000,
--         (SELECT MIN(id_usuario) FROM usuarios), (SELECT MIN(id_habitacion) FROM habitaciones));

-- Stock negativo
-- UPDATE productos SET stock = -1 WHERE id_producto = (SELECT MIN(id_producto) FROM productos);

ROLLBACK;

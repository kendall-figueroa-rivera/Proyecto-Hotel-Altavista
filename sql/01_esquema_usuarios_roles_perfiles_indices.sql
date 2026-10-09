/* =================================================================
   SC-503 Administracion de Bases de Datos
   Esquema exclusivo + Usuarios + Roles + Perfiles + Indices
   Proyecto reutilizado: Hotel Lenguaje (origen: SC-504)

   COMO EJECUTAR ESTE ARCHIVO (Oracle Autonomous DB / ATP, via wallet):

   PASO 1 -> Conectarse como ADMIN (SQL Developer o Database Actions)
             y correr la SECCION 1 (crea el esquema exclusivo).

   PASO 2 -> Cambiar la conexion al nuevo usuario ADMIN_HOTEL (la clave
             que se puso en la SECCION 1) y, conectado como ADMIN_HOTEL,
             ejecutar COMPLETO el script ya existente:
                 oracle_hotel_lenguaje.sql
             Esto recrea las 16 tablas, las 10 vistas, los paquetes,
             funciones y triggers -- pero esta vez bajo el esquema
             exclusivo del proyecto, no bajo ADMIN.

   PASO 3 -> Volver a conectarse como ADMIN (tiene privilegios para
             crear roles/perfiles y para otorgar permisos sobre objetos
             de otro esquema) y correr la SECCION 2 en adelante.

   Cambien TODAS las claves marcadas como <<CAMBIAR_...>> antes de
   entregar el proyecto, y no las suban a GitHub en texto plano
   (usar variables de entorno, igual que se recomienda mas abajo
   para application.properties).
   ================================================================= */


/* =================================================================
   SECCION 1: ESQUEMA EXCLUSIVO DEL PROYECTO
   (ejecutar conectado como ADMIN)
   ================================================================= */

-- Usuario/esquema solicitado por el equipo: admin_hotel / AdminHotel2026!
-- Nota: Oracle Autonomous exige minimo 12 caracteres y mezcla de mayusculas,
-- minusculas y numeros en la clave. "AdminHotel" (10 caracteres, sin numero)
-- no pasa esa validacion -- por eso quedo "AdminHotel2026!". Si quieren
-- otra clave, que cumpla esos 3 requisitos y el minimo de 12 caracteres.
CREATE USER admin_hotel IDENTIFIED BY "AdminHotel2026!"
  DEFAULT TABLESPACE DATA
  TEMPORARY TABLESPACE TEMP
  QUOTA UNLIMITED ON DATA;

GRANT CONNECT, RESOURCE TO admin_hotel;
GRANT CREATE VIEW              TO admin_hotel;
GRANT CREATE MATERIALIZED VIEW TO admin_hotel;
GRANT CREATE TRIGGER           TO admin_hotel;
GRANT CREATE PROCEDURE         TO admin_hotel;
GRANT CREATE SEQUENCE          TO admin_hotel;
GRANT UNLIMITED TABLESPACE     TO admin_hotel;

-- A partir de aqui: desconectarse, volver a conectar como admin_hotel,
-- y ejecutar completo el archivo oracle_hotel_lenguaje.sql (PASO 2 de arriba).
-- No se repite ese contenido aqui porque ya existe y funciona tal cual.


/* =================================================================
   SECCION 2: PERFILES (sesiones, inactividad, uso de recursos)
   (ejecutar conectado como ADMIN)
   ================================================================= */

-- Habilita que Oracle aplique los limites de los perfiles.
-- En ATP el usuario ADMIN normalmente puede ejecutar esto; si da error
-- de privilegios, se documenta la excepcion en el informe y se continua
-- (los perfiles igual quedan creados y asociados a los usuarios).
ALTER SYSTEM SET RESOURCE_LIMIT = TRUE;

CREATE PROFILE perfil_administrador LIMIT
  SESSIONS_PER_USER      UNLIMITED
  IDLE_TIME              60          -- minutos de inactividad antes de cerrar sesion
  CONNECT_TIME           UNLIMITED
  FAILED_LOGIN_ATTEMPTS  5
  PASSWORD_LOCK_TIME     1           -- dias bloqueado tras agotar intentos
  CPU_PER_SESSION        UNLIMITED;

CREATE PROFILE perfil_recepcion LIMIT
  SESSIONS_PER_USER      2           -- maximo 2 sesiones simultaneas
  IDLE_TIME              30
  CONNECT_TIME           480         -- 8 horas, turno laboral
  FAILED_LOGIN_ATTEMPTS  3
  PASSWORD_LOCK_TIME     (1/48)      -- 30 minutos
  CPU_PER_SESSION        12000;      -- centesimas de segundo de CPU

CREATE PROFILE perfil_consulta LIMIT
  SESSIONS_PER_USER      1
  IDLE_TIME              15
  CONNECT_TIME           240
  FAILED_LOGIN_ATTEMPTS  3
  PASSWORD_LOCK_TIME     (1/48)
  CPU_PER_SESSION        6000;


/* =================================================================
   SECCION 3: ROLES A NIVEL DE BASE DE DATOS
   (distintos de la tabla ROLES de la aplicacion: estos son roles
   reales de Oracle, para accesos directos a la base -- DBA, personal
   de recepcion haciendo consultas/soporte, y auditoria/reportes)
   (ejecutar conectado como ADMIN)
   ================================================================= */

CREATE ROLE rol_admin_sistema;
CREATE ROLE rol_recepcion;
CREATE ROLE rol_consulta;

-- Rol administrador: control total sobre las tablas del proyecto
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.roles                  TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.usuarios               TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.habitaciones           TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.ofertas                TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.reservaciones          TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.metodos_pago           TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.pagos                  TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.facturas               TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.cargos_extra           TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.reembolsos             TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.productos              TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.ventas                 TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.detalle_venta          TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.login_auditoria        TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.auditoria_reservaciones TO rol_admin_sistema;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.auditoria_usuarios     TO rol_admin_sistema;
GRANT EXECUTE ON admin_hotel.pkg_reservaciones  TO rol_admin_sistema;
GRANT EXECUTE ON admin_hotel.pkg_pagos          TO rol_admin_sistema;
GRANT EXECUTE ON admin_hotel.pkg_usuarios       TO rol_admin_sistema;
GRANT EXECUTE ON admin_hotel.pkg_habitaciones   TO rol_admin_sistema;
GRANT EXECUTE ON admin_hotel.pkg_reportes       TO rol_admin_sistema;

-- Rol recepcion: solo tablas operativas del dia a dia, sin usuarios ni auditoria
GRANT SELECT, INSERT, UPDATE ON admin_hotel.reservaciones   TO rol_recepcion;
GRANT SELECT, INSERT, UPDATE ON admin_hotel.pagos           TO rol_recepcion;
GRANT SELECT, INSERT         ON admin_hotel.facturas        TO rol_recepcion;
GRANT SELECT, INSERT         ON admin_hotel.cargos_extra    TO rol_recepcion;
GRANT SELECT, UPDATE         ON admin_hotel.habitaciones    TO rol_recepcion;
GRANT SELECT                 ON admin_hotel.productos       TO rol_recepcion;
GRANT SELECT, INSERT         ON admin_hotel.ventas          TO rol_recepcion;
GRANT SELECT, INSERT         ON admin_hotel.detalle_venta   TO rol_recepcion;
GRANT SELECT                 ON admin_hotel.ofertas         TO rol_recepcion;
GRANT SELECT                 ON admin_hotel.metodos_pago    TO rol_recepcion;
GRANT EXECUTE ON admin_hotel.pkg_reservaciones TO rol_recepcion;
GRANT EXECUTE ON admin_hotel.pkg_pagos         TO rol_recepcion;

-- Rol consulta: solo lectura sobre vistas de reportes (auditoria/gerencia)
GRANT SELECT ON admin_hotel.vw_ReservacionesActivas        TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_HabitacionesDisponibilidad  TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_PagosDetalle                TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_VentasDetalle               TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_UsuariosConRol               TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_OfertasVigentes             TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_IngresosPorMes               TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_AuditoriaReservaciones       TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_StockProductos               TO rol_consulta;
GRANT SELECT ON admin_hotel.vw_Dashboard                    TO rol_consulta;


/* =================================================================
   SECCION 4: USUARIOS (minimo 3 que pide el Avance 1 + el usuario
   de servicio que usara la aplicacion Spring Boot)
   (ejecutar conectado como ADMIN)
   ================================================================= */

CREATE USER usr_admin_sistema IDENTIFIED BY "AdminSistema2026!"
  DEFAULT TABLESPACE DATA PROFILE perfil_administrador;
GRANT CONNECT TO usr_admin_sistema;
GRANT rol_admin_sistema TO usr_admin_sistema;

CREATE USER usr_recepcion IDENTIFIED BY "Recepcion2026!"
  DEFAULT TABLESPACE DATA PROFILE perfil_recepcion;
GRANT CONNECT TO usr_recepcion;
GRANT rol_recepcion TO usr_recepcion;

CREATE USER usr_consulta IDENTIFIED BY "Consulta2026!"
  DEFAULT TABLESPACE DATA PROFILE perfil_consulta;
GRANT CONNECT TO usr_consulta;
GRANT rol_consulta TO usr_consulta;

-- Usuario de servicio que usara la aplicacion Spring Boot (reemplaza
-- la conexion actual que usa ADMIN directamente -- eso hay que corregirlo
-- en application.properties despues de correr este script).
CREATE USER admin_hotel_app IDENTIFIED BY "AdminHotelApp2026!"
  DEFAULT TABLESPACE DATA PROFILE perfil_recepcion;
GRANT CONNECT TO admin_hotel_app;
GRANT rol_admin_sistema TO admin_hotel_app;
-- Nota: la app ya controla sus propios roles de negocio (ADMIN/RECEPCIONISTA/
-- CLIENTE) en la tabla ROLES + Spring Security, por eso el usuario de
-- conexion de la app necesita el permiso amplio (rol_admin_sistema);
-- los 3 usuarios de arriba (usr_admin_sistema, usr_recepcion, usr_consulta)
-- son para acceso DIRECTO a la base (SQL Developer, pruebas, auditoria del
-- profesor), que es lo que pide la rubrica de Avance 1.


/* =================================================================
   SECCION 5: INDICES INICIALES
   Oracle NO crea indice automatico en columnas de llave foranea
   (solo en PK y UNIQUE). Estos cubren las FKs y las columnas que
   mas se consultan (disponibilidad de habitaciones, reportes).
   (ejecutar conectado como admin_hotel, o como ADMIN indicando el
   esquema en el nombre de la tabla)
   ================================================================= */

CREATE INDEX ix_usuarios_rol             ON admin_hotel.usuarios(id_rol);
CREATE INDEX ix_reservaciones_usuario    ON admin_hotel.reservaciones(id_usuario);
CREATE INDEX ix_reservaciones_habitacion ON admin_hotel.reservaciones(id_habitacion);
CREATE INDEX ix_reservaciones_oferta     ON admin_hotel.reservaciones(id_oferta);
CREATE INDEX ix_reservaciones_fechas     ON admin_hotel.reservaciones(fecha_entrada, fecha_salida);
CREATE INDEX ix_pagos_reservacion        ON admin_hotel.pagos(id_reservacion);
CREATE INDEX ix_pagos_metodo             ON admin_hotel.pagos(id_metodo_pago);
CREATE INDEX ix_facturas_pago            ON admin_hotel.facturas(id_pago);
CREATE INDEX ix_cargos_extra_reserv      ON admin_hotel.cargos_extra(id_reservacion);
CREATE INDEX ix_reembolsos_pago          ON admin_hotel.reembolsos(id_pago);
CREATE INDEX ix_ventas_usuario           ON admin_hotel.ventas(id_usuario);
CREATE INDEX ix_detalle_venta_venta      ON admin_hotel.detalle_venta(id_venta);
CREATE INDEX ix_detalle_venta_producto   ON admin_hotel.detalle_venta(id_producto);
CREATE INDEX ix_login_auditoria_usuario  ON admin_hotel.login_auditoria(id_usuario);
CREATE INDEX ix_auditoria_reserv_resid   ON admin_hotel.auditoria_reservaciones(id_reservacion);

COMMIT;

/* =================================================================
   RESUMEN
   Esquema exclusivo:  1  (admin_hotel)
   Perfiles:            3  (administrador, recepcion, consulta)
   Roles de BD:         3  (rol_admin_sistema, rol_recepcion, rol_consulta)
   Usuarios:            4  (usr_admin_sistema, usr_recepcion, usr_consulta,
                             admin_hotel_app)
   Indices nuevos:     15
   ================================================================= */

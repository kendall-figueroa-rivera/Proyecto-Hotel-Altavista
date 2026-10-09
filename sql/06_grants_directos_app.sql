/* =================================================================
   Permisos DIRECTOS al usuario de la aplicacion (admin_hotel_app)
   En vez de depender de que el rol ROL_ADMIN_SISTEMA se active bien
   en cada sesion JDBC, se otorgan los permisos directo al usuario.
   Esto elimina cualquier ambiguedad y es inmediato.

   Ejecutar conectado como ADMIN.
   ================================================================= */

-- Por si acaso: asegura que todos los roles otorgados se activen por defecto
ALTER USER admin_hotel_app DEFAULT ROLE ALL;

-- Tablas (16)
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.roles                   TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.usuarios                TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.habitaciones            TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.ofertas                 TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.reservaciones           TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.metodos_pago            TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.pagos                   TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.facturas                TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.cargos_extra            TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.reembolsos              TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.productos               TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.ventas                  TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.detalle_venta           TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.login_auditoria         TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.auditoria_reservaciones TO admin_hotel_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON admin_hotel.auditoria_usuarios      TO admin_hotel_app;

-- Paquetes y procedimientos
GRANT EXECUTE ON admin_hotel.pkg_reservaciones    TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.pkg_pagos            TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.pkg_usuarios         TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.pkg_habitaciones     TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.pkg_reportes         TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.sp_registrarventa    TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.sp_generarcargoextra TO admin_hotel_app;

-- Funciones
GRANT EXECUTE ON admin_hotel.fn_calculartotalreservacion    TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_habitaciondisponible        TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_totalingresosporfecha       TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_reservacionesactivasusuario TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_ingresostotaleshabitacion   TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_ofertavigente               TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_totalnochesreservacion      TO admin_hotel_app;
GRANT EXECUTE ON admin_hotel.fn_porcentajeocupacion         TO admin_hotel_app;

-- Vistas (10)
GRANT SELECT ON admin_hotel.vw_reservacionesactivas       TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_habitacionesdisponibilidad TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_pagosdetalle               TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_ventasdetalle              TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_usuariosconrol             TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_ofertasvigentes            TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_ingresospormes             TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_auditoriareservaciones     TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_stockproductos             TO admin_hotel_app;
GRANT SELECT ON admin_hotel.vw_dashboard                  TO admin_hotel_app;

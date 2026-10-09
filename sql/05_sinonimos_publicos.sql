/* =================================================================
   Sinonimos publicos: resuelve ORA-00942 "table or view does not exist"
   cuando un usuario distinto al dueno del esquema (admin_hotel_app,
   usr_admin_sistema, usr_recepcion, usr_consulta) hace referencias
   SIN calificar el esquema (ej: "SELECT * FROM usuarios" en vez de
   "SELECT * FROM admin_hotel.usuarios", que es justo como Hibernate/
   JPA arma las consultas).

   Ejecutar conectado como ADMIN.
   ================================================================= */

-- Tablas (16)
CREATE PUBLIC SYNONYM roles                  FOR admin_hotel.roles;
CREATE PUBLIC SYNONYM usuarios               FOR admin_hotel.usuarios;
CREATE PUBLIC SYNONYM habitaciones           FOR admin_hotel.habitaciones;
CREATE PUBLIC SYNONYM ofertas                FOR admin_hotel.ofertas;
CREATE PUBLIC SYNONYM reservaciones          FOR admin_hotel.reservaciones;
CREATE PUBLIC SYNONYM metodos_pago           FOR admin_hotel.metodos_pago;
CREATE PUBLIC SYNONYM pagos                  FOR admin_hotel.pagos;
CREATE PUBLIC SYNONYM facturas               FOR admin_hotel.facturas;
CREATE PUBLIC SYNONYM cargos_extra           FOR admin_hotel.cargos_extra;
CREATE PUBLIC SYNONYM reembolsos             FOR admin_hotel.reembolsos;
CREATE PUBLIC SYNONYM productos              FOR admin_hotel.productos;
CREATE PUBLIC SYNONYM ventas                 FOR admin_hotel.ventas;
CREATE PUBLIC SYNONYM detalle_venta          FOR admin_hotel.detalle_venta;
CREATE PUBLIC SYNONYM login_auditoria        FOR admin_hotel.login_auditoria;
CREATE PUBLIC SYNONYM auditoria_reservaciones FOR admin_hotel.auditoria_reservaciones;
CREATE PUBLIC SYNONYM auditoria_usuarios     FOR admin_hotel.auditoria_usuarios;

-- Vistas (10)
CREATE PUBLIC SYNONYM vw_reservacionesactivas       FOR admin_hotel.vw_reservacionesactivas;
CREATE PUBLIC SYNONYM vw_habitacionesdisponibilidad FOR admin_hotel.vw_habitacionesdisponibilidad;
CREATE PUBLIC SYNONYM vw_pagosdetalle               FOR admin_hotel.vw_pagosdetalle;
CREATE PUBLIC SYNONYM vw_ventasdetalle              FOR admin_hotel.vw_ventasdetalle;
CREATE PUBLIC SYNONYM vw_usuariosconrol             FOR admin_hotel.vw_usuariosconrol;
CREATE PUBLIC SYNONYM vw_ofertasvigentes            FOR admin_hotel.vw_ofertasvigentes;
CREATE PUBLIC SYNONYM vw_ingresospormes             FOR admin_hotel.vw_ingresospormes;
CREATE PUBLIC SYNONYM vw_auditoriareservaciones     FOR admin_hotel.vw_auditoriareservaciones;
CREATE PUBLIC SYNONYM vw_stockproductos             FOR admin_hotel.vw_stockproductos;
CREATE PUBLIC SYNONYM vw_dashboard                  FOR admin_hotel.vw_dashboard;

-- Paquetes (5) -- la app invoca procedimientos almacenados dentro de estos
CREATE PUBLIC SYNONYM pkg_reservaciones  FOR admin_hotel.pkg_reservaciones;
CREATE PUBLIC SYNONYM pkg_pagos          FOR admin_hotel.pkg_pagos;
CREATE PUBLIC SYNONYM pkg_usuarios       FOR admin_hotel.pkg_usuarios;
CREATE PUBLIC SYNONYM pkg_habitaciones   FOR admin_hotel.pkg_habitaciones;
CREATE PUBLIC SYNONYM pkg_reportes       FOR admin_hotel.pkg_reportes;

-- Procedimientos sueltos (2)
CREATE PUBLIC SYNONYM sp_registrarventa     FOR admin_hotel.sp_registrarventa;
CREATE PUBLIC SYNONYM sp_generarcargoextra  FOR admin_hotel.sp_generarcargoextra;

-- Funciones (8)
CREATE PUBLIC SYNONYM fn_calculartotalreservacion    FOR admin_hotel.fn_calculartotalreservacion;
CREATE PUBLIC SYNONYM fn_habitaciondisponible         FOR admin_hotel.fn_habitaciondisponible;
CREATE PUBLIC SYNONYM fn_totalingresosporfecha        FOR admin_hotel.fn_totalingresosporfecha;
CREATE PUBLIC SYNONYM fn_reservacionesactivasusuario  FOR admin_hotel.fn_reservacionesactivasusuario;
CREATE PUBLIC SYNONYM fn_ingresostotaleshabitacion    FOR admin_hotel.fn_ingresostotaleshabitacion;
CREATE PUBLIC SYNONYM fn_ofertavigente                FOR admin_hotel.fn_ofertavigente;
CREATE PUBLIC SYNONYM fn_totalnochesreservacion       FOR admin_hotel.fn_totalnochesreservacion;
CREATE PUBLIC SYNONYM fn_porcentajeocupacion          FOR admin_hotel.fn_porcentajeocupacion;

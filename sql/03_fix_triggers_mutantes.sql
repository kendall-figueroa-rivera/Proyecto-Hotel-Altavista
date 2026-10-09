/* =================================================================
   Fix: triggers con error de "tabla mutante" (ORA-04091)
   Ejecutar conectado como admin_hotel (el dueno del esquema).
   Esto NO toca tablas, grants ni indices -- solo reemplaza
   la definicion de estos 2 triggers por una version segura
   (patron COMPOUND TRIGGER: primero recolecta filas afectadas,
   y hace la consulta a la misma tabla DESPUES del INSERT/UPDATE,
   no durante).
   ================================================================= */

CREATE OR REPLACE TRIGGER trg_ActualizarEstadoHabitacion
FOR INSERT OR UPDATE ON reservaciones
COMPOUND TRIGGER

  TYPE t_habitacion_estado IS RECORD (
    id_habitacion   NUMBER,
    estado          VARCHAR2(50),
    fecha_entrada   DATE,
    fecha_salida    DATE,
    id_reservacion  NUMBER
  );
  TYPE t_lista IS TABLE OF t_habitacion_estado INDEX BY PLS_INTEGER;
  v_lista t_lista;
  v_idx   PLS_INTEGER := 0;

  AFTER EACH ROW IS
  BEGIN
    v_idx := v_idx + 1;
    v_lista(v_idx).id_habitacion  := :NEW.id_habitacion;
    v_lista(v_idx).estado         := :NEW.estado;
    v_lista(v_idx).fecha_entrada  := :NEW.fecha_entrada;
    v_lista(v_idx).fecha_salida   := :NEW.fecha_salida;
    v_lista(v_idx).id_reservacion := :NEW.id_reservacion;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
    v_tiene_activa NUMBER;
  BEGIN
    FOR i IN 1..v_idx LOOP
      IF v_lista(i).estado = 'confirmada' THEN
        IF v_lista(i).fecha_entrada <= TRUNC(SYSDATE) AND v_lista(i).fecha_salida > TRUNC(SYSDATE) THEN
          UPDATE habitaciones SET estado = 'ocupada'
          WHERE id_habitacion = v_lista(i).id_habitacion;
        ELSIF v_lista(i).fecha_entrada > TRUNC(SYSDATE) THEN
          UPDATE habitaciones SET estado = 'reservada'
          WHERE id_habitacion = v_lista(i).id_habitacion;
        END IF;
      ELSIF v_lista(i).estado = 'cancelada' THEN
        SELECT COUNT(*) INTO v_tiene_activa
        FROM reservaciones
        WHERE id_habitacion = v_lista(i).id_habitacion
          AND estado = 'confirmada'
          AND fecha_salida > TRUNC(SYSDATE)
          AND id_reservacion != v_lista(i).id_reservacion;
        IF v_tiene_activa = 0 THEN
          UPDATE habitaciones SET estado = 'disponible'
          WHERE id_habitacion = v_lista(i).id_habitacion;
        END IF;
      END IF;
    END LOOP;
  END AFTER STATEMENT;

END trg_ActualizarEstadoHabitacion;
/


CREATE OR REPLACE TRIGGER trg_ActualizarTotalVenta
FOR INSERT OR UPDATE ON detalle_venta
COMPOUND TRIGGER

  TYPE t_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_ventas_afectadas t_ids;
  v_idx PLS_INTEGER := 0;

  AFTER EACH ROW IS
  BEGIN
    v_idx := v_idx + 1;
    v_ventas_afectadas(v_idx) := :NEW.id_venta;
  END AFTER EACH ROW;

  AFTER STATEMENT IS
  BEGIN
    FOR i IN 1..v_idx LOOP
      UPDATE ventas
      SET total = (SELECT NVL(SUM(subtotal), 0) FROM detalle_venta WHERE id_venta = v_ventas_afectadas(i))
      WHERE id_venta = v_ventas_afectadas(i);
    END LOOP;
  END AFTER STATEMENT;

END trg_ActualizarTotalVenta;
/

COMMIT;

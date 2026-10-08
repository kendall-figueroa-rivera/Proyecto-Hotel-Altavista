USE hotelLenguaje;
GO

-- Arreglar trigger: marcar habitación como reservada al confirmar
-- (no solo cuando ya entró el huésped)
CREATE OR ALTER TRIGGER trg_ActualizarEstadoHabitacion
ON reservaciones
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON

    -- Habitación pasa a "reservada" cuando hay reservación confirmada (futura o activa)
    UPDATE habitaciones
    SET estado = 'reservada'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion FROM inserted
        WHERE estado = 'confirmada'
    )
    AND id_habitacion NOT IN (
        -- Solo si no está ya ocupada por alguien que ya entró
        SELECT id_habitacion FROM reservaciones
        WHERE estado = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )

    -- Habitación pasa a "ocupada" si el huésped ya entró hoy
    UPDATE habitaciones
    SET estado = 'ocupada'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion FROM inserted
        WHERE estado = 'confirmada'
          AND fecha_entrada <= CAST(GETDATE() AS DATE)
          AND fecha_salida  >  CAST(GETDATE() AS DATE)
    )

    -- Habitación vuelve a "disponible" si se cancela y no hay otras reservas activas
    UPDATE habitaciones
    SET estado = 'disponible'
    WHERE id_habitacion IN (
        SELECT DISTINCT id_habitacion FROM inserted WHERE estado = 'cancelada'
    )
    AND id_habitacion NOT IN (
        SELECT id_habitacion FROM reservaciones
        WHERE estado = 'confirmada'
          AND fecha_salida > CAST(GETDATE() AS DATE)
    )
END
GO

PRINT 'Trigger actualizado correctamente'
GO

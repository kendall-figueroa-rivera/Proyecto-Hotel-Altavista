package com.hotel.sistema.repository;

import com.hotel.sistema.entity.Habitacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

@Repository
public interface HabitacionRepository extends JpaRepository<Habitacion, Integer> {
    List<Habitacion> findByEstado(String estado);
    List<Habitacion> findByTipo(String tipo);

    // Habitaciones disponibles (sin reserva activa en el rango de fechas)
    @Query("SELECT h FROM Habitacion h WHERE h.idHabitacion NOT IN " +
           "(SELECT r.habitacion.idHabitacion FROM Reservacion r " +
           "WHERE r.estado NOT IN ('cancelada') " +
           "AND r.fechaEntrada < :fechaSalida AND r.fechaSalida > :fechaEntrada)")
    List<Habitacion> findHabitacionesDisponibles(LocalDate fechaEntrada, LocalDate fechaSalida);

@Modifying
@Transactional
@Query(
    value = """
        BEGIN
            pkg_habitaciones.crear(
                :numero,
                :tipo,
                :precioNoche,
                :estado,
                :mensaje
            );
        END;
        """,
    nativeQuery = true
)
void crearHabitacionSP(
        @Param("numero") Integer numero,
        @Param("tipo") String tipo,
        @Param("precioNoche") Double precioNoche,
        @Param("estado") String estado,
        @Param("mensaje") String mensaje
);
}

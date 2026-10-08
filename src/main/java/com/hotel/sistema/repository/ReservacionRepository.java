package com.hotel.sistema.repository;

import com.hotel.sistema.entity.Reservacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ReservacionRepository extends JpaRepository<Reservacion, Integer> {
    List<Reservacion> findByUsuario_IdUsuario(Integer idUsuario);
    List<Reservacion> findByEstado(String estado);
    List<Reservacion> findByHabitacion_IdHabitacion(Integer idHabitacion);
}

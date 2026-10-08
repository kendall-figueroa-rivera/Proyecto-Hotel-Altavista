package com.hotel.sistema.service;

import com.hotel.sistema.entity.*;
import com.hotel.sistema.repository.*;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@SuppressWarnings("null")
public class ReservacionService {

    @Autowired private ReservacionRepository reservacionRepository;
    @Autowired private HabitacionRepository  habitacionRepository;
    @Autowired private EntityManager         entityManager;

    public List<Reservacion> listarTodas() {
        return reservacionRepository.findAll();
    }

    public Optional<Reservacion> buscarPorId(Integer id) {
        if (id == null) return Optional.empty();
        return reservacionRepository.findById(id);
    }

    public List<Reservacion> listarPorUsuario(Integer idUsuario) {
        return reservacionRepository.findByUsuario_IdUsuario(idUsuario);
    }

    public List<Habitacion> buscarHabitacionesDisponibles(LocalDate entrada, LocalDate salida) {
        return habitacionRepository.findHabitacionesDisponibles(entrada, salida);
    }

    // Buscar proxima disponibilidad de una habitacion
    public String buscarProximaDisponibilidad(Integer idHabitacion, LocalDate desde) {
        try {
            // Buscar la reservacion activa mas proxima que bloquea esta habitacion
            List<Reservacion> reservaciones = reservacionRepository
                    .findByHabitacion_IdHabitacion(idHabitacion);

            LocalDate proximaDisponible = null;
            for (Reservacion r : reservaciones) {
                if (!r.getEstado().equals("cancelada")
                        && r.getFechaSalida().isAfter(desde)) {
                    if (proximaDisponible == null
                            || r.getFechaSalida().isAfter(proximaDisponible)) {
                        proximaDisponible = r.getFechaSalida();
                    }
                }
            }

            if (proximaDisponible != null) {
                return "La habitacion no esta disponible en esa fecha. " +
                       "Proxima disponibilidad: " + proximaDisponible.toString();
            }
            return "La habitacion no esta disponible en esas fechas.";
        } catch (Exception e) {
            return "La habitacion no esta disponible en esas fechas.";
        }
    }

    @Transactional
    public Reservacion guardar(Reservacion reservacion) {
        return reservacionRepository.save(reservacion);
    }

    @Transactional
    public void cancelar(Integer idReservacion) {
        if (idReservacion == null) return;
        reservacionRepository.findById(idReservacion).ifPresent(r -> {
            r.setEstado("cancelada");
            reservacionRepository.save(r);
        });
    }

    // Llamada al paquete Oracle pkg_reservaciones.crear
    @Transactional
    public String crearReservacionSP(Integer idUsuario, Integer idHabitacion,
                                      LocalDate fechaEntrada, LocalDate fechaSalida,
                                      Integer idOferta) {
        try {
            StoredProcedureQuery q = entityManager
                    .createStoredProcedureQuery("pkg_reservaciones.crear");

            q.registerStoredProcedureParameter("p_idUsuario",    Integer.class,   ParameterMode.IN);
            q.registerStoredProcedureParameter("p_idHabitacion", Integer.class,   ParameterMode.IN);
            q.registerStoredProcedureParameter("p_fechaEntrada", java.sql.Date.class, ParameterMode.IN);
            q.registerStoredProcedureParameter("p_fechaSalida",  java.sql.Date.class, ParameterMode.IN);
            q.registerStoredProcedureParameter("p_idOferta",     Integer.class,   ParameterMode.IN);
            q.registerStoredProcedureParameter("p_mensaje",      String.class,    ParameterMode.OUT);

            q.setParameter("p_idUsuario",    idUsuario);
            q.setParameter("p_idHabitacion", idHabitacion);
            q.setParameter("p_fechaEntrada", java.sql.Date.valueOf(fechaEntrada));
            q.setParameter("p_fechaSalida",  java.sql.Date.valueOf(fechaSalida));
            q.setParameter("p_idOferta",     idOferta);

            q.execute();
            return (String) q.getOutputParameterValue("p_mensaje");
        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }
}
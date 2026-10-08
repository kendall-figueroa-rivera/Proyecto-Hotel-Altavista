package com.hotel.sistema.service;

import com.hotel.sistema.entity.Habitacion;
import com.hotel.sistema.repository.HabitacionRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@SuppressWarnings("null")
public class HabitacionService {

    @Autowired
    private HabitacionRepository habitacionRepository;

    @Autowired
    private EntityManager entityManager;

    public List<Habitacion> listarTodas() {
        return habitacionRepository.findAll();
    }

    public Optional<Habitacion> buscarPorId(Integer id) {
        if (id == null) {
            return Optional.empty();
        }

        return habitacionRepository.findById(id);
    }

    @Transactional
    public String guardarSP(Habitacion habitacion) {

        if (habitacion.getIdHabitacion() == null) {
            return crearSP(habitacion);
        }

        return actualizarSP(habitacion);
    }

    @Transactional
    public String crearSP(Habitacion habitacion) {
        try {
            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery("PKG_HABITACIONES.CREAR");

            procedimiento.registerStoredProcedureParameter(
                    "p_numero",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_tipo",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_precioNoche",
                    BigDecimal.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_estado",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter("p_numero", habitacion.getNumero());
            procedimiento.setParameter("p_tipo", habitacion.getTipo());
            procedimiento.setParameter("p_precioNoche", habitacion.getPrecioNoche());
            procedimiento.setParameter("p_estado", habitacion.getEstado());

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue("p_mensaje");

        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String actualizarSP(Habitacion habitacion) {
        try {
            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery("PKG_HABITACIONES.ACTUALIZAR");

            procedimiento.registerStoredProcedureParameter(
                    "p_idHabitacion",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_tipo",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_precioNoche",
                    BigDecimal.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_estado",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_idHabitacion",
                    habitacion.getIdHabitacion()
            );

            procedimiento.setParameter("p_tipo", habitacion.getTipo());
            procedimiento.setParameter("p_precioNoche", habitacion.getPrecioNoche());
            procedimiento.setParameter("p_estado", habitacion.getEstado());

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue("p_mensaje");

        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String eliminarSP(Integer idHabitacion) {
        try {
            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery("PKG_HABITACIONES.ELIMINAR");

            procedimiento.registerStoredProcedureParameter(
                    "p_idHabitacion",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter("p_idHabitacion", idHabitacion);

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue("p_mensaje");

        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }
}
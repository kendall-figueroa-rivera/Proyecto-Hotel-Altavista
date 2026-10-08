package com.hotel.sistema.service;

import com.hotel.sistema.entity.Oferta;
import com.hotel.sistema.repository.OfertaRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@SuppressWarnings("null")
public class OfertaService {

    @Autowired
    private OfertaRepository ofertaRepository;

    @Autowired
    private EntityManager entityManager;

    public List<Oferta> listarTodas() {
        return ofertaRepository.findAll();
    }

    public List<Oferta> listarVigentes() {
        return ofertaRepository.findByFechaFinGreaterThanEqual(LocalDate.now());
    }

    public Optional<Oferta> buscarPorId(Integer id) {
        if (id == null) {
            return Optional.empty();
        }

        return ofertaRepository.findById(id);
    }

    @Transactional
    public Oferta guardar(Oferta oferta) {
        return ofertaRepository.save(oferta);
    }

    @Transactional
    public String crearOfertaSP(
            String titulo,
            String descripcion,
            BigDecimal descuento,
            LocalDate fechaInicio,
            LocalDate fechaFin
    ) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_CREAROFERTA"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "p_titulo",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_descripcion",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_descuento",
                    BigDecimal.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_fechaInicio",
                    Date.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_fechaFin",
                    Date.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_titulo",
                    titulo
            );

            procedimiento.setParameter(
                    "p_descripcion",
                    descripcion
            );

            procedimiento.setParameter(
                    "p_descuento",
                    descuento
            );

            procedimiento.setParameter(
                    "p_fechaInicio",
                    Date.valueOf(fechaInicio)
            );

            procedimiento.setParameter(
                    "p_fechaFin",
                    Date.valueOf(fechaFin)
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "p_mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String eliminarOfertaSP(Integer idOferta) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_ELIMINAROFERTA"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "p_idOferta",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_idOferta",
                    idOferta
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "p_mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }
}
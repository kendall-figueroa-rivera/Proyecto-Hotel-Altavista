package com.hotel.sistema.service;

import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class CargoExtraService {

    @Autowired
    private EntityManager entityManager;

    @Transactional
    public String generarCargoExtraSP(
            Integer idReservacion,
            String descripcion,
            BigDecimal monto
    ) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_GENERARCARGOEXTRA"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "p_idReservacion",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_descripcion",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_monto",
                    BigDecimal.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_idReservacion",
                    idReservacion
            );

            procedimiento.setParameter(
                    "p_descripcion",
                    descripcion
            );

            procedimiento.setParameter(
                    "p_monto",
                    monto
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "p_mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional(readOnly = true)
    public List<Object[]> listarPorReservacion(
            Integer idReservacion
    ) {

        return entityManager.createNativeQuery("""
                SELECT descripcion, monto
                FROM cargos_extra
                WHERE id_reservacion = :idReservacion
                ORDER BY id_cargo_extra DESC
                """)
                .setParameter(
                        "idReservacion",
                        idReservacion
                )
                .getResultList();
    }

    @Transactional(readOnly = true)
    public BigDecimal obtenerTotalPorReservacion(
            Integer idReservacion
    ) {

        Object resultado =
                entityManager.createNativeQuery("""
                        SELECT NVL(SUM(monto), 0)
                        FROM cargos_extra
                        WHERE id_reservacion = :idReservacion
                        """)
                        .setParameter(
                                "idReservacion",
                                idReservacion
                        )
                        .getSingleResult();

        return new BigDecimal(
                resultado.toString()
        );
    }
}
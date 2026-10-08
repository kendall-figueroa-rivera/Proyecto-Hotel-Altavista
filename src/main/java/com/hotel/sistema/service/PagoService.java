package com.hotel.sistema.service;

import com.hotel.sistema.entity.Pago;
import com.hotel.sistema.entity.Reservacion;
import com.hotel.sistema.repository.PagoRepository;
import com.hotel.sistema.repository.ReservacionRepository;
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
public class PagoService {

    @Autowired private PagoRepository        pagoRepository;
    @Autowired private ReservacionRepository  reservacionRepository;
    @Autowired private EntityManager          entityManager;

    public List<Pago> listarTodos() { return pagoRepository.findAll(); }

    public List<Pago> listarPorUsuarioId(Integer idUsuario) {
        return pagoRepository.findByUsuarioId(idUsuario);
    }

    public Optional<Pago> buscarPorId(Integer id) {
        if (id == null) return Optional.empty();
        return pagoRepository.findById(id);
    }

    public List<Pago> listarPorReservacion(Integer idReservacion) {
        return pagoRepository.findByReservacion_IdReservacion(idReservacion);
    }

    public String validarMonto(Integer idReservacion, BigDecimal monto) {
        Optional<Reservacion> res = reservacionRepository.findById(idReservacion);
        if (res.isEmpty()) return "ERROR: Reservacion no encontrada";

        BigDecimal totalReservacion = res.get().getTotalPago();
        if (totalReservacion == null) return "ERROR: La reservacion no tiene total definido";

        List<Pago> pagosAnteriores = pagoRepository.findByReservacion_IdReservacion(idReservacion);
        BigDecimal totalPagado = pagosAnteriores.stream()
                .filter(p -> p.getEstado().equals("completado"))
                .map(Pago::getMonto)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal pendiente = totalReservacion.subtract(totalPagado);

        if (pendiente.compareTo(BigDecimal.ZERO) <= 0)
            return "ERROR: Esta reservacion ya esta pagada completamente";

        if (monto.compareTo(pendiente) > 0)
            return "ERROR: El monto ₡" + monto + " supera el saldo pendiente ₡" + pendiente;

        return "OK";
    }

    @Transactional
    public String procesarPagoSP(Integer idReservacion, Integer idMetodoPago, BigDecimal monto) {
        try {
            String validacion = validarMonto(idReservacion, monto);
            if (validacion.startsWith("ERROR")) return validacion;

            StoredProcedureQuery q = entityManager
                    .createStoredProcedureQuery("pkg_pagos.procesar");
            q.registerStoredProcedureParameter("p_idReservacion", Integer.class,    ParameterMode.IN);
            q.registerStoredProcedureParameter("p_idMetodoPago",  Integer.class,    ParameterMode.IN);
            q.registerStoredProcedureParameter("p_monto",         BigDecimal.class, ParameterMode.IN);
            q.registerStoredProcedureParameter("p_mensaje",       String.class,     ParameterMode.OUT);
            q.setParameter("p_idReservacion", idReservacion);
            q.setParameter("p_idMetodoPago",  idMetodoPago);
            q.setParameter("p_monto",         monto);
            q.execute();

            String mensaje = (String) q.getOutputParameterValue("p_mensaje");

            if (mensaje != null && mensaje.startsWith("OK")) {
                reservacionRepository.findById(idReservacion).ifPresent(r -> {
                    // Recalcular total pagado
                    BigDecimal totalPagado = pagoRepository
                            .findByReservacion_IdReservacion(idReservacion)
                            .stream()
                            .filter(p -> p.getEstado().equals("completado"))
                            .map(Pago::getMonto)
                            .reduce(BigDecimal.ZERO, BigDecimal::add);

                    if (totalPagado.compareTo(r.getTotalPago()) >= 0) {
                        r.setEstado("pagada");
                    } else {
                        // Pago parcial — mantener activa
                        r.setEstado("pago_parcial");
                    }
                    reservacionRepository.save(r);
                });
            }
            return mensaje;
        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String cancelarReservacionSP(Integer idReservacion, String motivo, boolean reembolso) {
        try {
            StoredProcedureQuery q = entityManager
                    .createStoredProcedureQuery("pkg_reservaciones.cancelar");
            q.registerStoredProcedureParameter("p_idReservacion",    Integer.class, ParameterMode.IN);
            q.registerStoredProcedureParameter("p_motivo",           String.class,  ParameterMode.IN);
            q.registerStoredProcedureParameter("p_aplicarReembolso", Integer.class, ParameterMode.IN);
            q.registerStoredProcedureParameter("p_mensaje",          String.class,  ParameterMode.OUT);
            q.setParameter("p_idReservacion",    idReservacion);
            q.setParameter("p_motivo",           motivo);
            q.setParameter("p_aplicarReembolso", reembolso ? 1 : 0);
            q.execute();
            return (String) q.getOutputParameterValue("p_mensaje");
        } catch (Exception e) {
            return "ERROR: " + e.getMessage();
        }
    }
}

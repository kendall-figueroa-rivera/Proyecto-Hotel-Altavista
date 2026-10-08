package com.hotel.sistema.service;

import com.hotel.sistema.dto.ReporteVentaProductoDTO;
import com.hotel.sistema.dto.ReporteReservacionUsuarioDTO;
import jakarta.persistence.EntityManager;
import org.hibernate.Session;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

@Service
public class ReporteService {

    @Autowired
    private EntityManager entityManager;

    public List<ReporteVentaProductoDTO> obtenerReporteVentasProductos() {
        List<ReporteVentaProductoDTO> lista = new ArrayList<>();

        Session session = entityManager.unwrap(Session.class);

        session.doWork(connection -> {
            String sql = "{call pkg_reportes.reporte_ventas_productos(?)}";

            try (CallableStatement stmt = connection.prepareCall(sql)) {
                stmt.registerOutParameter(1, oracle.jdbc.OracleTypes.CURSOR);
                stmt.execute();

                try (ResultSet rs = (ResultSet) stmt.getObject(1)) {
                    while (rs.next()) {
                        ReporteVentaProductoDTO dto = new ReporteVentaProductoDTO();
                        dto.setNombre(rs.getString("nombre"));
                        dto.setPrecio(rs.getBigDecimal("precio"));
                        dto.setStock(rs.getInt("stock"));
                        dto.setUnidadesVendidas(rs.getInt("unidades_vendidas"));
                        dto.setIngresosTotales(rs.getBigDecimal("ingresos_totales"));
                        lista.add(dto);
                    }
                }
            }
        });

        return lista;
    }

    public List<ReporteReservacionUsuarioDTO> obtenerReporteReservacionesUsuario() {
        List<ReporteReservacionUsuarioDTO> lista = new ArrayList<>();

        Session session = entityManager.unwrap(Session.class);

        session.doWork(connection -> {
            String sql = "{call pkg_reportes.reporte_reservaciones_usuario(?)}";

            try (CallableStatement stmt = connection.prepareCall(sql)) {
                stmt.registerOutParameter(1, oracle.jdbc.OracleTypes.CURSOR);
                stmt.execute();

                try (ResultSet rs = (ResultSet) stmt.getObject(1)) {
                    while (rs.next()) {
                        ReporteReservacionUsuarioDTO dto = new ReporteReservacionUsuarioDTO();
                        dto.setHuesped(rs.getString("huesped"));
                        dto.setTotalReservaciones(rs.getInt("total_reservaciones"));
                        dto.setTotalPagado(rs.getBigDecimal("total_pagado"));
                        lista.add(dto);
                    }
                }
            }
        });

        return lista;
    }

}
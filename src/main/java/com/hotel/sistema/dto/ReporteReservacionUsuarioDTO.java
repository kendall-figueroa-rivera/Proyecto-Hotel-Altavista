package com.hotel.sistema.dto;

import java.math.BigDecimal;

public class ReporteReservacionUsuarioDTO {

    private String huesped;
    private Integer totalReservaciones;
    private BigDecimal totalPagado;

    // Getters y Setters
    public String getHuesped() { return huesped; }
    public void setHuesped(String huesped) { this.huesped = huesped; }

    public Integer getTotalReservaciones() { return totalReservaciones; }
    public void setTotalReservaciones(Integer totalReservaciones) { this.totalReservaciones = totalReservaciones; }

    public BigDecimal getTotalPagado() { return totalPagado; }
    public void setTotalPagado(BigDecimal totalPagado) { this.totalPagado = totalPagado; }
}
package com.hotel.sistema.dto;

import java.math.BigDecimal;

public class ReporteVentaProductoDTO {

    private String nombre;
    private BigDecimal precio;
    private Integer stock;
    private Integer unidadesVendidas;
    private BigDecimal ingresosTotales;

    // Getters y Setters
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public BigDecimal getPrecio() { return precio; }
    public void setPrecio(BigDecimal precio) { this.precio = precio; }

    public Integer getStock() { return stock; }
    public void setStock(Integer stock) { this.stock = stock; }

    public Integer getUnidadesVendidas() { return unidadesVendidas; }
    public void setUnidadesVendidas(Integer unidadesVendidas) { this.unidadesVendidas = unidadesVendidas; }

    public BigDecimal getIngresosTotales() { return ingresosTotales; }
    public void setIngresosTotales(BigDecimal ingresosTotales) { this.ingresosTotales = ingresosTotales; }
}
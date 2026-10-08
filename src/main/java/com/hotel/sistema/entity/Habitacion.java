package com.hotel.sistema.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "habitaciones")
public class Habitacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_habitacion")
    private Integer idHabitacion;

    @Column(name = "numero", nullable = false, unique = true)
    private Integer numero;

    @Column(name = "tipo", nullable = false, length = 50)
    private String tipo;

    @Column(name = "precio_noche", nullable = false, precision = 10, scale = 2)
    private BigDecimal precioNoche;

    @Column(name = "estado", nullable = false, length = 50)
    private String estado;

    // ── Getters y Setters ──────────────────────
    public Integer getIdHabitacion() { return idHabitacion; }
    public void setIdHabitacion(Integer idHabitacion) { this.idHabitacion = idHabitacion; }

    public Integer getNumero() { return numero; }
    public void setNumero(Integer numero) { this.numero = numero; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public BigDecimal getPrecioNoche() { return precioNoche; }
    public void setPrecioNoche(BigDecimal precioNoche) { this.precioNoche = precioNoche; }

    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
}

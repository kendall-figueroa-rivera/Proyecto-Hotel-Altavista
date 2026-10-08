package com.hotel.sistema.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "cargos_extra")
public class CargoExtra {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_cargo_extra")
    private Integer idCargoExtra;

    @Column(name = "descripcion", nullable = false, length = 255)
    private String descripcion;

    @Column(name = "monto", nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @ManyToOne
    @JoinColumn(name = "id_reservacion", nullable = false)
    private Reservacion reservacion;

    public Integer getIdCargoExtra() { return idCargoExtra; }
    public void setIdCargoExtra(Integer idCargoExtra) { this.idCargoExtra = idCargoExtra; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public BigDecimal getMonto() { return monto; }
    public void setMonto(BigDecimal monto) { this.monto = monto; }

    public Reservacion getReservacion() { return reservacion; }
    public void setReservacion(Reservacion reservacion) { this.reservacion = reservacion; }
}

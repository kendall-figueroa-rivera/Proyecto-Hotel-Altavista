package com.hotel.sistema.entity;

import jakarta.persistence.*;
import org.hibernate.annotations.Immutable;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Immutable                                   // Le dice a Hibernate: esto NO se inserta ni actualiza, solo se lee
@Table(name = "vw_reservacionesactivas")
public class ReservacionActiva {

    @Id
    @Column(name = "id_reservacion")
    private Integer idReservacion;

    @Column(name = "huesped")
    private String huesped;

    @Column(name = "identificacion")
    private String identificacion;

    @Column(name = "correo")
    private String correo;

    @Column(name = "habitacion")
    private Integer habitacion;

    @Column(name = "tipo_habitacion")
    private String tipoHabitacion;

    @Column(name = "fecha_entrada")
    private LocalDate fechaEntrada;

    @Column(name = "fecha_salida")
    private LocalDate fechaSalida;

    @Column(name = "noches")
    private Integer noches;

    @Column(name = "total_pago")
    private BigDecimal totalPago;

    @Column(name = "estado")
    private String estado;

    @Column(name = "oferta_aplicada")
    private String ofertaAplicada;

    @Column(name = "descuento")
    private BigDecimal descuento;

    // ── Solo Getters (es de solo lectura, no necesita Setters) ──
    public Integer getIdReservacion() { return idReservacion; }
    public String getHuesped() { return huesped; }
    public String getIdentificacion() { return identificacion; }
    public String getCorreo() { return correo; }
    public Integer getHabitacion() { return habitacion; }
    public String getTipoHabitacion() { return tipoHabitacion; }
    public LocalDate getFechaEntrada() { return fechaEntrada; }
    public LocalDate getFechaSalida() { return fechaSalida; }
    public Integer getNoches() { return noches; }
    public BigDecimal getTotalPago() { return totalPago; }
    public String getEstado() { return estado; }
    public String getOfertaAplicada() { return ofertaAplicada; }
    public BigDecimal getDescuento() { return descuento; }
}
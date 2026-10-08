package com.hotel.sistema.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "reembolsos")
public class Reembolso {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_reembolso")
    private Integer idReembolso;

    @Column(name = "fecha_reembolso", nullable = false)
    private LocalDateTime fechaReembolso;

    @Column(name = "monto", nullable = false, precision = 10, scale = 2)
    private BigDecimal monto;

    @Column(name = "motivo", length = 255)
    private String motivo;

    @ManyToOne
    @JoinColumn(name = "id_pago", nullable = false)
    private Pago pago;

    public Integer getIdReembolso() { return idReembolso; }
    public void setIdReembolso(Integer idReembolso) { this.idReembolso = idReembolso; }

    public LocalDateTime getFechaReembolso() { return fechaReembolso; }
    public void setFechaReembolso(LocalDateTime fechaReembolso) { this.fechaReembolso = fechaReembolso; }

    public BigDecimal getMonto() { return monto; }
    public void setMonto(BigDecimal monto) { this.monto = monto; }

    public String getMotivo() { return motivo; }
    public void setMotivo(String motivo) { this.motivo = motivo; }

    public Pago getPago() { return pago; }
    public void setPago(Pago pago) { this.pago = pago; }
}

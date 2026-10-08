package com.hotel.sistema.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "login_auditoria")
public class LoginAuditoria {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_login")
    private Integer idLogin;

    @Column(name = "ip", nullable = false, length = 45)
    private String ip;

    @Column(name = "fecha_login", nullable = false)
    private LocalDateTime fechaLogin;

    @Column(name = "dispositivo", length = 100)
    private String dispositivo;

    @ManyToOne
    @JoinColumn(name = "id_usuario", nullable = false)
    private Usuario usuario;

    public Integer getIdLogin() { return idLogin; }
    public void setIdLogin(Integer idLogin) { this.idLogin = idLogin; }

    public String getIp() { return ip; }
    public void setIp(String ip) { this.ip = ip; }

    public LocalDateTime getFechaLogin() { return fechaLogin; }
    public void setFechaLogin(LocalDateTime fechaLogin) { this.fechaLogin = fechaLogin; }

    public String getDispositivo() { return dispositivo; }
    public void setDispositivo(String dispositivo) { this.dispositivo = dispositivo; }

    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }
}

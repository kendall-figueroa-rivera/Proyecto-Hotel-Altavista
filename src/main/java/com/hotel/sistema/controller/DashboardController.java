package com.hotel.sistema.controller;

import com.hotel.sistema.repository.*;
import com.hotel.sistema.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class DashboardController {

    @Autowired private UsuarioRepository     usuarioRepository;
    @Autowired private HabitacionRepository  habitacionRepository;
    @Autowired private ReservacionRepository reservacionRepository;
    @Autowired private ProductoRepository    productoRepository;
    @Autowired private PagoRepository        pagoRepository;
    @Autowired private UsuarioService        usuarioService;

    @GetMapping("/dashboard")
    public String dashboard(Model model, Authentication auth) {

        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {
            // Dashboard especifico para CLIENTE
            usuarioService.buscarPorUsername(auth.getName()).ifPresent(u -> {
                // Solo sus reservaciones
                model.addAttribute("misReservaciones",
                        reservacionRepository.findByUsuario_IdUsuario(u.getIdUsuario()));
                // Sus pagos
                model.addAttribute("misPagos",
                        pagoRepository.findByUsuarioId(u.getIdUsuario()));
                // Habitaciones disponibles
                model.addAttribute("habitacionesDisp",
                        habitacionRepository.findByEstado("disponible").size());
                model.addAttribute("totalMisReservaciones",
                        reservacionRepository.findByUsuario_IdUsuario(u.getIdUsuario()).size());
            });
            return "dashboard/cliente";
        }

        // Dashboard para ADMIN y RECEPCIONISTA
        model.addAttribute("totalUsuarios",         usuarioRepository.count());
        model.addAttribute("totalHabitaciones",     habitacionRepository.count());
        model.addAttribute("habitacionesDisp",      habitacionRepository.findByEstado("disponible").size());
        model.addAttribute("habitacionesOcupadas",  habitacionRepository.findByEstado("ocupada").size());
        model.addAttribute("totalReservaciones",    reservacionRepository.count());
        model.addAttribute("reservacionesActivas",  reservacionRepository.findByEstado("confirmada").size());
        model.addAttribute("totalProductos",        productoRepository.count());
        model.addAttribute("totalPagos",            pagoRepository.count());
        return "dashboard/index";
    }

    @GetMapping("/")
    public String root() {
        return "redirect:/dashboard";
    }
}

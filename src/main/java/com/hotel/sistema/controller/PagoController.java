package com.hotel.sistema.controller;

import com.hotel.sistema.repository.MetodoPagoRepository;
import com.hotel.sistema.repository.ReservacionRepository;
import com.hotel.sistema.service.PagoService;
import com.hotel.sistema.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.List;

@Controller
@RequestMapping("/pagos")
public class PagoController {

    @Autowired private PagoService           pagoService;
    @Autowired private ReservacionRepository  reservacionRepository;
    @Autowired private MetodoPagoRepository   metodoPagoRepository;
    @Autowired private UsuarioService         usuarioService;

    @GetMapping
    public String listar(Model model, Authentication auth) {
        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {
            // Cliente solo ve SUS pagos
            usuarioService.buscarPorUsername(auth.getName()).ifPresent(u ->
                model.addAttribute("pagos",
                    pagoService.listarPorUsuarioId(u.getIdUsuario()))
            );
            model.addAttribute("esCliente", true);
        } else {
            model.addAttribute("pagos", pagoService.listarTodos());
            model.addAttribute("esCliente", false);
        }
        return "pagos/lista";
    }

    @GetMapping("/nuevo")
    public String nuevoForm(Model model, Authentication auth) {
        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {
            // Cliente solo puede pagar SUS reservaciones pendientes
            usuarioService.buscarPorUsername(auth.getName()).ifPresent(u -> {
                List<?> misReservaciones = reservacionRepository
                        .findByUsuario_IdUsuario(u.getIdUsuario())
                        .stream()
                        .filter(r -> r.getEstado().equals("confirmada")
                                  || r.getEstado().equals("pago_parcial"))
                        .toList();
                model.addAttribute("reservaciones", misReservaciones);
            });
        } else {
            model.addAttribute("reservaciones",
                reservacionRepository.findAll().stream()
                    .filter(r -> r.getEstado().equals("confirmada")
                              || r.getEstado().equals("pago_parcial"))
                    .toList());
        }

        model.addAttribute("metodos", metodoPagoRepository.findAll());
        model.addAttribute("esCliente", esCliente);
        return "pagos/formulario";
    }

    @PostMapping("/procesar")
    public String procesar(@RequestParam Integer idReservacion,
                           @RequestParam Integer idMetodoPago,
                           @RequestParam BigDecimal monto,
                           RedirectAttributes ra) {
        String resultado = pagoService.procesarPagoSP(idReservacion, idMetodoPago, monto);
        if (resultado != null && resultado.startsWith("OK")) {
            ra.addFlashAttribute("exito", resultado.replace("OK: ", ""));
        } else {
            ra.addFlashAttribute("error", resultado != null
                    ? resultado.replace("ERROR: ", "") : "Error al procesar pago");
            return "redirect:/pagos/nuevo";
        }
        return "redirect:/pagos";
    }
}

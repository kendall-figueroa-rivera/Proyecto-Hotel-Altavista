package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Reservacion;
import com.hotel.sistema.service.CargoExtraService;
import com.hotel.sistema.service.ReservacionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;

@Controller
@RequestMapping("/cargos-extra")
public class CargoExtraController {

    @Autowired
    private CargoExtraService cargoExtraService;

    @Autowired
    private ReservacionService reservacionService;

    @GetMapping("/nuevo/{idReservacion}")
    public String mostrarFormulario(@PathVariable Integer idReservacion,
                                    Model model,
                                    RedirectAttributes ra) {

        Reservacion reservacion = reservacionService.buscarPorId(idReservacion)
                .orElse(null);

        if (reservacion == null) {
            ra.addFlashAttribute("error", "La reservación no existe.");
            return "redirect:/reservaciones";
        }

        model.addAttribute("reservacion", reservacion);

        return "cargos-extra/formulario";
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Integer idReservacion,
                          @RequestParam String descripcion,
                          @RequestParam BigDecimal monto,
                          RedirectAttributes ra) {

        if (descripcion == null || descripcion.trim().isEmpty()) {
            ra.addFlashAttribute("error", "La descripción es obligatoria.");
            return "redirect:/cargos-extra/nuevo/" + idReservacion;
        }

        if (monto == null || monto.compareTo(BigDecimal.ZERO) <= 0) {
            ra.addFlashAttribute("error", "El monto debe ser mayor que cero.");
            return "redirect:/cargos-extra/nuevo/" + idReservacion;
        }

        String resultado = cargoExtraService.generarCargoExtraSP(
                idReservacion,
                descripcion.trim(),
                monto
        );

        if (resultado != null && resultado.startsWith("OK")) {
            ra.addFlashAttribute(
                    "exito",
                    resultado.replace("OK: ", "")
            );

            return "redirect:/reservaciones/detalle/" + idReservacion;
        }

        ra.addFlashAttribute(
                "error",
                resultado != null
                        ? resultado.replace("ERROR: ", "")
                        : "No se pudo registrar el cargo extra."
        );

        return "redirect:/cargos-extra/nuevo/" + idReservacion;
    }
}

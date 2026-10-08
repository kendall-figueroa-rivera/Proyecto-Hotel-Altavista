package com.hotel.sistema.controller;

import com.hotel.sistema.service.ReporteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/reportes")
public class ReporteController {

    @Autowired
    private ReporteService reporteService;

    @GetMapping("/ventas-productos")
    public String reporteVentasProductos(Model model) {
        model.addAttribute("reporte", reporteService.obtenerReporteVentasProductos());
        return "reportes/ventas-productos";
    }

    @GetMapping("/reservaciones-usuario")
    public String reporteReservacionesUsuario(Model model) {
        model.addAttribute("reporte", reporteService.obtenerReporteReservacionesUsuario());
        return "reportes/reservaciones-usuario";
    }

}
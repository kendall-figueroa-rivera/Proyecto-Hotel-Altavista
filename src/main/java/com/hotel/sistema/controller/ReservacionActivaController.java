package com.hotel.sistema.controller;

import com.hotel.sistema.repository.ReservacionActivaRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
@RequestMapping("/reportes")
public class ReservacionActivaController {

    @Autowired
    private ReservacionActivaRepository reservacionActivaRepository;

    @GetMapping("/reservaciones-activas")
    public String listar(Model model) {
        model.addAttribute("reservacionesActivas", reservacionActivaRepository.findAll());
        return "reportes/reservaciones-activas";
    }

}
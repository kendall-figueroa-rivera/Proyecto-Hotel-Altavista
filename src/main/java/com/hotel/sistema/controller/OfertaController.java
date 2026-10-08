package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Oferta;
import com.hotel.sistema.service.OfertaService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/ofertas")
public class OfertaController {

    @Autowired
    private OfertaService ofertaService;

    @GetMapping
    public String listar(Model model) {

        model.addAttribute(
                "ofertas",
                ofertaService.listarTodas()
        );

        return "ofertas/lista";
    }

    @GetMapping("/nueva")
    public String nuevaForm(Model model) {

        model.addAttribute(
                "oferta",
                new Oferta()
        );

        return "ofertas/formulario";
    }

    @PostMapping("/guardar")
    public String guardar(
            @ModelAttribute Oferta oferta,
            RedirectAttributes ra
    ) {

        if (oferta.getIdOferta() == null) {

            String resultado =
                    ofertaService.crearOfertaSP(
                            oferta.getTitulo(),
                            oferta.getDescripcion(),
                            oferta.getDescuento(),
                            oferta.getFechaInicio(),
                            oferta.getFechaFin()
                    );

            if (resultado != null && resultado.startsWith("ERROR")) {

                ra.addFlashAttribute(
                        "error",
                        resultado.replace("ERROR: ", "")
                );

            } else {

                ra.addFlashAttribute(
                        "exito",
                        resultado
                );
            }

        } else {

            ofertaService.guardar(oferta);

            ra.addFlashAttribute(
                    "exito",
                    "Oferta actualizada correctamente."
            );
        }

        return "redirect:/ofertas";
    }

    @GetMapping("/editar/{id}")
    public String editarForm(
            @PathVariable Integer id,
            Model model
    ) {

        ofertaService.buscarPorId(id)
                .ifPresent(oferta ->
                        model.addAttribute(
                                "oferta",
                                oferta
                        )
                );

        return "ofertas/formulario";
    }

    @GetMapping("/eliminar/{id}")
    public String eliminar(
            @PathVariable Integer id,
            RedirectAttributes ra
    ) {

        String resultado =
                ofertaService.eliminarOfertaSP(id);

        if (resultado != null && resultado.startsWith("ERROR")) {

            ra.addFlashAttribute(
                    "error",
                    resultado.replace("ERROR: ", "")
            );

        } else {

            ra.addFlashAttribute(
                    "exito",
                    resultado
            );
        }

        return "redirect:/ofertas";
    }
}
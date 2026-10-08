package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Producto;
import com.hotel.sistema.repository.UsuarioRepository;
import com.hotel.sistema.service.ProductoService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/productos")
public class ProductoController {

    @Autowired
    private ProductoService productoService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @GetMapping
    public String listar(Model model) {

        model.addAttribute(
                "productos",
                productoService.listarTodos()
        );

        return "productos/lista";
    }

    @GetMapping("/nuevo")
    public String nuevoForm(Model model) {

        model.addAttribute(
                "producto",
                new Producto()
        );

        return "productos/formulario";
    }

    @PostMapping("/guardar")
    public String guardar(
            @ModelAttribute Producto producto,
            RedirectAttributes ra
    ) {

        if (producto.getIdProducto() == null) {

            String resultado =
                    productoService.crearProductoSP(
                            producto.getNombre(),
                            producto.getDescripcion(),
                            producto.getPrecio(),
                            producto.getStock()
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

            productoService.guardar(producto);

            ra.addFlashAttribute(
                    "exito",
                    "Producto actualizado correctamente."
            );
        }

        return "redirect:/productos";
    }

    @GetMapping("/editar/{id}")
    public String editarForm(
            @PathVariable Integer id,
            Model model
    ) {

        productoService.buscarPorId(id)
                .ifPresent(producto ->
                        model.addAttribute(
                                "producto",
                                producto
                        )
                );

        return "productos/formulario";
    }

    @GetMapping("/stock/{id}")
    public String stockForm(
            @PathVariable Integer id,
            Model model
    ) {

        productoService.buscarPorId(id)
                .ifPresent(producto ->
                        model.addAttribute(
                                "producto",
                                producto
                        )
                );

        return "productos/stock";
    }

    @PostMapping("/stock")
    public String actualizarStock(
            @RequestParam Integer idProducto,
            @RequestParam Integer stock,
            RedirectAttributes ra
    ) {

        String resultado =
                productoService.actualizarStockSP(
                        idProducto,
                        stock
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

        return "redirect:/productos";
    }

    @GetMapping("/eliminar/{id}")
    public String eliminar(
            @PathVariable Integer id,
            RedirectAttributes ra
    ) {

        productoService.eliminar(id);

        ra.addFlashAttribute(
                "exito",
                "Producto eliminado."
        );

        return "redirect:/productos";
    }

    @GetMapping("/vender/{id}")
    public String venderForm(
            @PathVariable Integer id,
            Model model
    ) {

        productoService.buscarPorId(id)
                .ifPresent(producto ->
                        model.addAttribute(
                                "producto",
                                producto
                        )
                );

        model.addAttribute(
                "usuarios",
                usuarioRepository.findAll()
        );

        return "productos/vender";
    }

    @PostMapping("/vender")
    public String vender(
            @RequestParam Integer idProducto,
            @RequestParam Integer idUsuario,
            @RequestParam Integer cantidad,
            RedirectAttributes ra
    ) {

        String resultado =
                productoService.registrarVentaSP(
                        idUsuario,
                        idProducto,
                        cantidad
                );

        if (resultado != null && resultado.startsWith("OK")) {

            ra.addFlashAttribute(
                    "exito",
                    resultado.replace("OK: ", "")
            );

        } else {

            ra.addFlashAttribute(
                    "error",
                    resultado == null
                            ? "No se recibió respuesta del procedimiento."
                            : resultado.replace("ERROR: ", "")
            );
        }

        return "redirect:/productos";
    }
}
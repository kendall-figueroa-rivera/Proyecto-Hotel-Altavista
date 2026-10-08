package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Usuario;
import com.hotel.sistema.repository.RolRepository;
import com.hotel.sistema.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/usuarios")
public class UsuarioController {

    @Autowired private UsuarioService usuarioService;
    @Autowired private RolRepository  rolRepository;

    @GetMapping
    public String listar(Model model) {
        model.addAttribute("usuarios", usuarioService.listarTodos());
        return "usuarios/lista";
    }

    @GetMapping("/eliminar/{id}")
    public String eliminar(@PathVariable Integer id, RedirectAttributes ra) {
        usuarioService.eliminar(id);
        ra.addFlashAttribute("exito", "Usuario eliminado.");
        return "redirect:/usuarios";
    }

    @GetMapping("/editar/{id}")
    public String editarForm(@PathVariable Integer id, Model model) {
        usuarioService.buscarPorId(id).ifPresent(u -> model.addAttribute("usuario", u));
        model.addAttribute("roles", rolRepository.findAll());
        return "usuarios/formulario";
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Integer        idUsuario,
                          @RequestParam String         nombre,
                          @RequestParam String         apellido1,
                          @RequestParam(required = false) String apellido2,
                          @RequestParam String         identificacion,
                          @RequestParam String         correo,
                          @RequestParam(required = false) String telefono,
                          @RequestParam String         username,
                          @RequestParam(required = false) Integer idRol,
                          RedirectAttributes ra) {
        // Buscar el usuario existente para no perder contraseña ni fecha
        usuarioService.buscarPorId(idUsuario).ifPresent(u -> {
            u.setNombre(nombre);
            u.setApellido1(apellido1);
            u.setApellido2(apellido2);
            u.setIdentificacion(identificacion);
            u.setCorreo(correo);
            u.setTelefono(telefono);
            u.setUsername(username);
            if (idRol != null) {
                rolRepository.findById(idRol).ifPresent(u::setRol);
            } else {
                u.setRol(null);
            }
            usuarioService.actualizar(u);
        });
        ra.addFlashAttribute("exito", "Usuario actualizado correctamente.");
        return "redirect:/usuarios";
    }
}

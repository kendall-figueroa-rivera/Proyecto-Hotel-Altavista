package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Rol;
import com.hotel.sistema.entity.Usuario;
import com.hotel.sistema.repository.RolRepository;
import com.hotel.sistema.service.UsuarioService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
public class AuthController {

    @Autowired private UsuarioService usuarioService;
    @Autowired private RolRepository rolRepository;

    @GetMapping("/login")
    public String loginPage(@RequestParam(value = "error",  required = false) String error,
                            @RequestParam(value = "logout", required = false) String logout,
                            Model model) {
        if (error  != null) model.addAttribute("error",  "Usuario o contraseña incorrectos.");
        if (logout != null) model.addAttribute("logout", "Sesión cerrada correctamente.");
        return "auth/login";
    }

    @GetMapping("/registro")
    public String registroPage(Model model) {
        List<Rol> roles = rolRepository.findAll();
        model.addAttribute("usuario", new Usuario());
        model.addAttribute("roles", roles);
        return "auth/registro";
    }

    @PostMapping("/registro")
    public String registrar(@ModelAttribute Usuario usuario,
                            @RequestParam(value = "idRol", required = false) Integer idRol,
                            RedirectAttributes ra) {
        try {
            // Asignar rol si se seleccionó uno
            if (idRol != null) {
                rolRepository.findById(idRol).ifPresent(usuario::setRol);
            }

            // Validar que el username no exista
            if (usuarioService.existeUsername(usuario.getUsername())) {
                ra.addFlashAttribute("error", "El nombre de usuario ya existe.");
                return "redirect:/registro";
            }

            usuarioService.registrar(usuario);
            ra.addFlashAttribute("exito", "¡Registro exitoso! Iniciá sesión.");
            return "redirect:/login";

        } catch (Exception e) {
            ra.addFlashAttribute("error", "Error al registrar: " + e.getMessage());
            return "redirect:/registro";
        }
    }
}

package com.hotel.sistema.controller;

import com.hotel.sistema.entity.Reservacion;
import com.hotel.sistema.repository.HabitacionRepository;
import com.hotel.sistema.repository.OfertaRepository;
import com.hotel.sistema.repository.UsuarioRepository;
import com.hotel.sistema.service.CargoExtraService;
import com.hotel.sistema.service.ReservacionService;
import com.hotel.sistema.service.UsuarioService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Controller
@RequestMapping("/reservaciones")
public class ReservacionController {

    @Autowired
    private ReservacionService reservacionService;

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private HabitacionRepository habitacionRepository;

    @Autowired
    private OfertaRepository ofertaRepository;

    @Autowired
    private UsuarioService usuarioService;

    @Autowired
    private CargoExtraService cargoExtraService;

    @GetMapping
    public String listar(Model model, Authentication auth) {

        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {

            usuarioService.buscarPorUsername(auth.getName()).ifPresent(usuario -> {

                List<Reservacion> misReservaciones =
                        reservacionService.listarPorUsuario(
                                usuario.getIdUsuario()
                        );

                model.addAttribute(
                        "reservaciones",
                        misReservaciones
                );

                model.addAttribute(
                        "esCliente",
                        true
                );
            });

        } else {

            model.addAttribute(
                    "reservaciones",
                    reservacionService.listarTodas()
            );

            model.addAttribute(
                    "esCliente",
                    false
            );
        }

        return "reservaciones/lista";
    }

    @GetMapping("/nueva")
    public String nuevaForm(
            Model model,
            Authentication auth
    ) {

        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {

            usuarioService.buscarPorUsername(auth.getName())
                    .ifPresent(usuario ->
                            model.addAttribute(
                                    "usuarioActual",
                                    usuario
                            )
                    );

        } else {

            model.addAttribute(
                    "usuarios",
                    usuarioRepository.findAll()
            );
        }

        model.addAttribute(
                "habitaciones",
                habitacionRepository.findByEstado("disponible")
        );

        model.addAttribute(
                "ofertas",
                ofertaRepository.findByFechaFinGreaterThanEqual(
                        LocalDate.now()
                )
        );

        model.addAttribute(
                "esCliente",
                esCliente
        );

        return "reservaciones/formulario";
    }

    @PostMapping("/guardar")
    public String guardar(
            @RequestParam(required = false) Integer idUsuario,
            @RequestParam Integer idHabitacion,
            @RequestParam String fechaEntrada,
            @RequestParam String fechaSalida,
            @RequestParam(required = false) Integer idOferta,
            @RequestParam(
                    required = false,
                    defaultValue = "0"
            ) BigDecimal totalPago,
            Authentication auth,
            RedirectAttributes ra
    ) {

        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        if (esCliente) {

            idUsuario = usuarioService.buscarPorUsername(auth.getName())
                    .map(usuario -> usuario.getIdUsuario())
                    .orElse(null);
        }

        if (idUsuario == null) {

            ra.addFlashAttribute(
                    "error",
                    "No se pudo identificar el usuario."
            );

            return "redirect:/reservaciones/nueva";
        }

        LocalDate entrada = LocalDate.parse(fechaEntrada);
        LocalDate salida = LocalDate.parse(fechaSalida);

        List<?> habitacionesDisponibles =
                reservacionService.buscarHabitacionesDisponibles(
                        entrada,
                        salida
                );

        boolean disponible = habitacionesDisponibles.stream()
                .anyMatch(habitacion -> {

                    if (habitacion instanceof
                            com.hotel.sistema.entity.Habitacion hab) {

                        return hab.getIdHabitacion()
                                .equals(idHabitacion);
                    }

                    return false;
                });

        if (!disponible) {

            String mensajeDisponibilidad =
                    reservacionService.buscarProximaDisponibilidad(
                            idHabitacion,
                            entrada
                    );

            ra.addFlashAttribute(
                    "error",
                    mensajeDisponibilidad
            );

            return "redirect:/reservaciones/nueva";
        }

        String resultado =
                reservacionService.crearReservacionSP(
                        idUsuario,
                        idHabitacion,
                        entrada,
                        salida,
                        idOferta
                );

        if (resultado != null &&
                resultado.startsWith("OK")) {

            ra.addFlashAttribute(
                    "exito",
                    resultado.replace("OK: ", "")
            );

        } else {

            ra.addFlashAttribute(
                    "error",
                    resultado != null
                            ? resultado.replace("ERROR: ", "")
                            : "Error al crear la reservación."
            );

            return "redirect:/reservaciones/nueva";
        }

        return "redirect:/reservaciones";
    }

    @GetMapping("/cancelar/{id}")
    public String cancelar(
            @PathVariable Integer id,
            RedirectAttributes ra
    ) {

        reservacionService.cancelar(id);

        ra.addFlashAttribute(
                "exito",
                "Reservación cancelada."
        );

        return "redirect:/reservaciones";
    }

    @GetMapping("/detalle/{id}")
    public String detalle(
            @PathVariable Integer id,
            Model model,
            Authentication auth
    ) {

        boolean esCliente = auth.getAuthorities()
                .contains(new SimpleGrantedAuthority("ROLE_CLIENTE"));

        reservacionService.buscarPorId(id)
                .ifPresent(reservacion -> {

                    if (esCliente) {

                        usuarioService.buscarPorUsername(
                                auth.getName()
                        ).ifPresent(usuario -> {

                            boolean esPropietario =
                                    reservacion.getUsuario()
                                            .getIdUsuario()
                                            .equals(
                                                    usuario.getIdUsuario()
                                            );

                            if (esPropietario) {

                                cargarDetalleReservacion(
                                        reservacion,
                                        model
                                );
                            }
                        });

                    } else {

                        cargarDetalleReservacion(
                                reservacion,
                                model
                        );
                    }
                });

        model.addAttribute(
                "esCliente",
                esCliente
        );

        return "reservaciones/detalle";
    }

    private void cargarDetalleReservacion(
            Reservacion reservacion,
            Model model
    ) {

        model.addAttribute(
                "reservacion",
                reservacion
        );

        long noches = ChronoUnit.DAYS.between(
                reservacion.getFechaEntrada(),
                reservacion.getFechaSalida()
        );

        model.addAttribute(
                "noches",
                noches
        );

        List<Object[]> cargosExtra =
                cargoExtraService.listarPorReservacion(
                        reservacion.getIdReservacion()
                );

        model.addAttribute(
                "cargosExtra",
                cargosExtra
        );

        BigDecimal totalCargosExtra =
                cargoExtraService.obtenerTotalPorReservacion(
                        reservacion.getIdReservacion()
                );

        BigDecimal totalReservacion =
                reservacion.getTotalPago() != null
                        ? reservacion.getTotalPago()
                        : BigDecimal.ZERO;

        BigDecimal totalFinal =
                totalReservacion.add(totalCargosExtra);

        model.addAttribute(
                "totalCargosExtra",
                totalCargosExtra
        );

        model.addAttribute(
                "totalFinal",
                totalFinal
        );
    }
}
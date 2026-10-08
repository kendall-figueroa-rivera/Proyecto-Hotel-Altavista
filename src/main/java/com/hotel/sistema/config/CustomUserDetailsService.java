package com.hotel.sistema.config;

import com.hotel.sistema.entity.Usuario;
import com.hotel.sistema.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + username));

        String rol = "ROLE_" + (usuario.getRol() != null
                ? usuario.getRol().getNombre().toUpperCase()
                : "CLIENTE");

        return new org.springframework.security.core.userdetails.User(
                usuario.getUsername(),
                usuario.getContrasena(),
                List.of(new SimpleGrantedAuthority(rol))
        );
    }
}

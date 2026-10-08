package com.hotel.sistema.service;

import com.hotel.sistema.entity.Usuario;
import com.hotel.sistema.repository.UsuarioRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@SuppressWarnings("null")
public class UsuarioService {

    @Autowired
    private UsuarioRepository usuarioRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    public List<Usuario> listarTodos() {
        return usuarioRepository.findAll();
    }

    public Optional<Usuario> buscarPorId(Integer id) {
        if (id == null) return Optional.empty();
        return usuarioRepository.findById(id);
    }

    public Optional<Usuario> buscarPorUsername(String username) {
        return usuarioRepository.findByUsername(username);
    }

    @Transactional
    public Usuario registrar(Usuario usuario) {
        // Encriptar contraseña antes de guardar
        usuario.setContrasena(passwordEncoder.encode(usuario.getContrasena()));
        usuario.setFechaRegistro(LocalDate.now());
        return usuarioRepository.save(usuario);
    }

    @Transactional
    public Usuario actualizar(Usuario usuario) {
        return usuarioRepository.save(usuario);
    }

    @Transactional
    public void eliminar(Integer id) {
        if (id != null) usuarioRepository.deleteById(id);
    }

    public boolean existeUsername(String username) {
        return usuarioRepository.existsByUsername(username);
    }
}

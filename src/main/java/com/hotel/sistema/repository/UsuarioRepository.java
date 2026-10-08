package com.hotel.sistema.repository;

import com.hotel.sistema.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Integer> {
    Optional<Usuario> findByUsername(String username);
    Optional<Usuario> findByCorreo(String correo);
    boolean existsByUsername(String username);
    boolean existsByIdentificacion(String identificacion);
}

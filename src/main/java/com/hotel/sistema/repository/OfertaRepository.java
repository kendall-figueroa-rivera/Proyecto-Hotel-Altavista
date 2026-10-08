package com.hotel.sistema.repository;
import com.hotel.sistema.entity.Oferta;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
@Repository
public interface OfertaRepository extends JpaRepository<Oferta, Integer> {
    List<Oferta> findByFechaFinGreaterThanEqual(LocalDate fecha);
}

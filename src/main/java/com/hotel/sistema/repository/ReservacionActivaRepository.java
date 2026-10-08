package com.hotel.sistema.repository;

import com.hotel.sistema.entity.ReservacionActiva;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ReservacionActivaRepository extends JpaRepository<ReservacionActiva, Integer> {
}
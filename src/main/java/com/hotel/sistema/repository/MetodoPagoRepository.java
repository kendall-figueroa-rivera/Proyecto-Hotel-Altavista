package com.hotel.sistema.repository;
import com.hotel.sistema.entity.MetodoPago;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
@Repository
public interface MetodoPagoRepository extends JpaRepository<MetodoPago, Integer> {}

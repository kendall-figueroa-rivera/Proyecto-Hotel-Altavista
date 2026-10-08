package com.hotel.sistema.repository;
import com.hotel.sistema.entity.Factura;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
@Repository
public interface FacturaRepository extends JpaRepository<Factura, Integer> {}

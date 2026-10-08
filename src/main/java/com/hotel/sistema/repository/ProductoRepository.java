package com.hotel.sistema.repository;
import com.hotel.sistema.entity.Producto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
@Repository
public interface ProductoRepository extends JpaRepository<Producto, Integer> {}

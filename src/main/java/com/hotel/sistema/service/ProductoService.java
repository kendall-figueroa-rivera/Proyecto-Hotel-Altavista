package com.hotel.sistema.service;

import com.hotel.sistema.entity.Producto;
import com.hotel.sistema.repository.ProductoRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.ParameterMode;
import jakarta.persistence.StoredProcedureQuery;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Service
@SuppressWarnings("null")
public class ProductoService {

    @Autowired
    private ProductoRepository productoRepository;

    @Autowired
    private EntityManager entityManager;

    public List<Producto> listarTodos() {
        return productoRepository.findAll();
    }

    public Optional<Producto> buscarPorId(Integer id) {
        if (id == null) {
            return Optional.empty();
        }

        return productoRepository.findById(id);
    }

    @Transactional
    public Producto guardar(Producto producto) {
        return productoRepository.save(producto);
    }

    @Transactional
    public void eliminar(Integer id) {
        if (id != null) {
            productoRepository.deleteById(id);
        }
    }

    @Transactional
    public String crearProductoSP(
            String nombre,
            String descripcion,
            BigDecimal precio,
            Integer stock
    ) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_CREARPRODUCTO"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "p_nombre",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_descripcion",
                    String.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_precio",
                    BigDecimal.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_stock",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_nombre",
                    nombre
            );

            procedimiento.setParameter(
                    "p_descripcion",
                    descripcion
            );

            procedimiento.setParameter(
                    "p_precio",
                    precio
            );

            procedimiento.setParameter(
                    "p_stock",
                    stock
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "p_mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String actualizarStockSP(
            Integer idProducto,
            Integer stock
    ) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_ACTUALIZARSTOCKPRODUCTO"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "p_idProducto",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_stock",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "p_mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "p_idProducto",
                    idProducto
            );

            procedimiento.setParameter(
                    "p_stock",
                    stock
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "p_mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }

    @Transactional
    public String registrarVentaSP(
            Integer idUsuario,
            Integer idProducto,
            Integer cantidad
    ) {
        try {

            StoredProcedureQuery procedimiento =
                    entityManager.createStoredProcedureQuery(
                            "SP_REGISTRARVENTA"
                    );

            procedimiento.registerStoredProcedureParameter(
                    "idUsuario",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "idProducto",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "cantidad",
                    Integer.class,
                    ParameterMode.IN
            );

            procedimiento.registerStoredProcedureParameter(
                    "mensaje",
                    String.class,
                    ParameterMode.OUT
            );

            procedimiento.setParameter(
                    "idUsuario",
                    idUsuario
            );

            procedimiento.setParameter(
                    "idProducto",
                    idProducto
            );

            procedimiento.setParameter(
                    "cantidad",
                    cantidad
            );

            procedimiento.execute();

            return (String) procedimiento.getOutputParameterValue(
                    "mensaje"
            );

        } catch (Exception e) {

            return "ERROR: " + e.getMessage();
        }
    }
}
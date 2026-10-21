package com.studiophoto.photoappbackend.order;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
    @Query("SELECT SUM(oi.quantity) FROM OrderItem oi")
    Long sumTotalQuantity();

    @Query("SELECT SUM(oi.quantity) FROM OrderItem oi WHERE oi.order.createdAt BETWEEN :start AND :end")
    Long sumQuantityByOrderCreatedAtBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query("SELECT oi.photoSize, SUM(oi.quantity) FROM OrderItem oi GROUP BY oi.photoSize ORDER BY SUM(oi.quantity) DESC")
    java.util.List<Object[]> countByPhotoSize();
}

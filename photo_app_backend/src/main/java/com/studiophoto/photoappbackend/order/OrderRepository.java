package com.studiophoto.photoappbackend.order;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    // Find all orders for a specific user, ordered by creation date descending
    List<Order> findByUserIdOrderByCreatedAtDesc(Integer userId);

    // Find all orders ordered by creation date descending
    List<Order> findAllByOrderByCreatedAtDesc();

    long countByStatus(OrderStatus status);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.status IN :statuses AND o.createdAt BETWEEN :start AND :end")
    BigDecimal sumTotalAmountByStatusInAndCreatedAtBetween(
            @Param("statuses") List<OrderStatus> statuses,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT new com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO(CONCAT(o.user.firstname, ' ', o.user.lastname), SUM(o.totalAmount)) " +
            "FROM Order o " +
            "WHERE o.status IN :statuses " +
            "GROUP BY o.user.id " +
            "ORDER BY SUM(o.totalAmount) DESC")
    List<com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO> findTopClientsByRevenue(@Param("statuses") List<OrderStatus> statuses, org.springframework.data.domain.Pageable pageable);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.status IN :statuses")
    BigDecimal sumTotalRevenue(@Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.status IN :statuses")
    long countCompletedOrders(@Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.user.id = :userId AND o.status IN :statuses AND o.createdAt BETWEEN :start AND :end")
    BigDecimal sumUserRevenueBetween(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses, @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.user.id = :userId AND o.status IN :statuses")
    long countOrdersByUserAndStatusIn(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.user.id = :userId AND o.status IN :statuses")
    BigDecimal sumTotalRevenueByUserAndStatusIn(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses);

    List<Order> findTop5ByOrderByCreatedAtDesc();

    List<Order> findByCreatedAtBetweenOrderByCreatedAtDesc(LocalDateTime start, LocalDateTime end);

    List<Order> findByUserIdAndCreatedAtAfterOrderByCreatedAtDesc(Integer userId, LocalDateTime after);
}

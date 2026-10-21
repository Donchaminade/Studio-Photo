package com.studiophoto.photoappbackend.order;

import org.springframework.data.jpa.repository.EntityGraph;
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

    @EntityGraph(attributePaths = {"user", "orderItems"})
    List<Order> findAllByOrderByCreatedAtDesc();

    long countByStatus(OrderStatus status);

    long countByStatusIn(List<OrderStatus> statuses);

    long countByCreatedAtBetween(LocalDateTime start, LocalDateTime end);

    /**
     * CA pertinent : statuts payés confirmés + paiement signalé par le client,
     * hors commandes remboursées. Utilise {@code o.totalAmount} persisté (pas un recalcul items).
     */
    String REVENUE_FILTER = "("
            + "o.status IN :statuses "
            + "OR (o.status = com.studiophoto.photoappbackend.order.OrderStatus.PENDING_PAYMENT "
            + "    AND upper(coalesce(o.paymentStatus, '')) IN ('CUSTOMER_REPORTED_PAID', 'PAID'))"
            + ") AND (o.refundStatus IS NULL OR o.refundStatus <> com.studiophoto.photoappbackend.order.RefundStatus.REFUNDED)";

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE " + REVENUE_FILTER + " AND o.createdAt BETWEEN :start AND :end")
    BigDecimal sumTotalAmountByStatusInAndCreatedAtBetween(
            @Param("statuses") List<OrderStatus> statuses,
            @Param("start") LocalDateTime start,
            @Param("end") LocalDateTime end);

    @Query("SELECT new com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO(CONCAT(o.user.firstname, ' ', o.user.lastname), SUM(o.totalAmount)) " +
            "FROM Order o " +
            "WHERE " + REVENUE_FILTER + " " +
            "GROUP BY o.user.id, o.user.firstname, o.user.lastname " +
            "ORDER BY SUM(o.totalAmount) DESC")
    List<com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO> findTopClientsByRevenue(@Param("statuses") List<OrderStatus> statuses, org.springframework.data.domain.Pageable pageable);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE " + REVENUE_FILTER)
    BigDecimal sumTotalRevenue(@Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT COUNT(o) FROM Order o WHERE " + REVENUE_FILTER)
    long countCompletedOrders(@Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.user.id = :userId AND " + REVENUE_FILTER + " AND o.createdAt BETWEEN :start AND :end")
    BigDecimal sumUserRevenueBetween(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses, @Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query("SELECT COUNT(o) FROM Order o WHERE o.user.id = :userId AND " + REVENUE_FILTER)
    long countOrdersByUserAndStatusIn(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses);

    @Query("SELECT SUM(o.totalAmount) FROM Order o WHERE o.user.id = :userId AND " + REVENUE_FILTER)
    BigDecimal sumTotalRevenueByUserAndStatusIn(@Param("userId") Integer userId, @Param("statuses") List<OrderStatus> statuses);

    @EntityGraph(attributePaths = {"user", "orderItems"})
    List<Order> findTop5ByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"user", "orderItems"})
    List<Order> findByCreatedAtBetweenOrderByCreatedAtDesc(LocalDateTime start, LocalDateTime end);

    List<Order> findByUserIdAndCreatedAtAfterOrderByCreatedAtDesc(Integer userId, LocalDateTime after);
}

package com.studiophoto.photoappbackend.order;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import com.studiophoto.photoappbackend.model.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "orders")
public class Order {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @JsonManagedReference
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL, orphanRemoval = true)
    @Builder.Default
    private List<OrderItem> orderItems = new ArrayList<>();

    @Column(unique = true)
    private String orderNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OrderStatus status;

    @Column(nullable = false)
    private BigDecimal totalAmount;

    @Column
    private String paymentMethod;

    @Column
    private String paymentStatus;

    @Column
    private String paymentReference;

    @Column
    private String paymentProofType;

    @Column(columnDefinition = "TEXT")
    private String paymentProofText;

    @Column
    private String paymentProofImageUrl;

    @Enumerated(EnumType.STRING)
    @Column(length = 32)
    @Builder.Default
    private RefundStatus refundStatus = RefundStatus.NONE;

    @Column(precision = 12, scale = 2)
    private BigDecimal refundAmount;

    @Column(columnDefinition = "TEXT")
    private String refundReason;

    @Column
    private String refundReference;

    private LocalDateTime refundedAt;

    @Column
    private String refundedBy;

    @Column
    private String deliveryAddress;

    @Column(nullable = false)
    private String deliveryType; // e.g., "Standard", "Xpress"

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (status == null) {
            status = OrderStatus.PENDING;
        }
        if (orderNumber == null) {
            orderNumber = UUID.randomUUID().toString();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    // Helper method to add an item and set the bidirectional relationship
    public void addOrderItem(OrderItem item) {
        orderItems.add(item);
        item.setOrder(this);
    }
}

package com.studiophoto.photoappbackend.order;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * DTO de réponse pour les commandes.
 * Garantit que tous les champs renvoyés au client Flutter sont non-null
 * avec des valeurs par défaut appropriées.
 */
public class OrderResponseDTO {

    private Long id;
    private List<OrderItemDTO> orderItems;
    private String status;
    private BigDecimal totalAmount;
    private String paymentMethod;
    private String paymentStatus;
    private String paymentReference;
    private String paymentProofType;
    private String paymentProofText;
    private String paymentProofImageUrl;
    private String refundStatus;
    private BigDecimal refundAmount;
    private String refundReason;
    private String refundReference;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime refundedAt;

    private String deliveryType;
    private String deliveryAddress;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    // ── Constructeur de mapping depuis l'entité ─────────────────────────────
    public static OrderResponseDTO from(Order order) {
        OrderResponseDTO dto = new OrderResponseDTO();
        dto.id = order.getId();
        dto.status = order.getStatus() != null ? order.getStatus().name() : "UNKNOWN";
        dto.totalAmount = order.getTotalAmount() != null ? order.getTotalAmount() : BigDecimal.ZERO;
        // Valeurs par défaut garanties
        dto.paymentMethod = order.getPaymentMethod() != null ? order.getPaymentMethod() : "NON_RENSEIGNE";
        dto.paymentStatus = order.getPaymentStatus() != null ? order.getPaymentStatus() : "PENDING_PAYMENT";
        dto.paymentReference = order.getPaymentReference();
        dto.paymentProofType = order.getPaymentProofType();
        dto.paymentProofText = order.getPaymentProofText();
        dto.paymentProofImageUrl = order.getPaymentProofImageUrl();
        dto.refundStatus = order.getRefundStatus() != null
                ? order.getRefundStatus().name()
                : RefundStatus.NONE.name();
        dto.refundAmount = order.getRefundAmount();
        dto.refundReason = order.getRefundReason();
        dto.refundReference = order.getRefundReference();
        dto.refundedAt = order.getRefundedAt();
        dto.deliveryType = order.getDeliveryType() != null ? order.getDeliveryType() : "Standard";
        dto.deliveryAddress = order.getDeliveryAddress();
        dto.createdAt = order.getCreatedAt() != null ? order.getCreatedAt() : LocalDateTime.now();
        dto.orderItems = order.getOrderItems() != null
                ? order.getOrderItems().stream()
                        .map(OrderItemDTO::from)
                        .collect(Collectors.toList())
                : List.of();
        return dto;
    }

    // ── Getters ────────────────────────────────────────────────────────────
    public Long getId() {
        return id;
    }

    public List<OrderItemDTO> getOrderItems() {
        return orderItems;
    }

    public String getStatus() {
        return status;
    }

    public BigDecimal getTotalAmount() {
        return totalAmount;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public String getPaymentReference() {
        return paymentReference;
    }

    public String getPaymentProofType() {
        return paymentProofType;
    }

    public String getPaymentProofText() {
        return paymentProofText;
    }

    public String getPaymentProofImageUrl() {
        return paymentProofImageUrl;
    }

    public String getRefundStatus() {
        return refundStatus;
    }

    public BigDecimal getRefundAmount() {
        return refundAmount;
    }

    public String getRefundReason() {
        return refundReason;
    }

    public String getRefundReference() {
        return refundReference;
    }

    public LocalDateTime getRefundedAt() {
        return refundedAt;
    }

    public String getDeliveryType() {
        return deliveryType;
    }

    public String getDeliveryAddress() {
        return deliveryAddress;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    // ── DTO imbriqué pour OrderItem ────────────────────────────────────────
    public static class OrderItemDTO {
        private Long id;
        private String imageUrl;
        private String photoSize;
        private int quantity;
        private BigDecimal pricePerUnit;
        private boolean withFrame;
        private Long frameId;
        private String frameName;
        private String frameImageUrl;
        private BigDecimal framePrice;
        private String studioPrintAdvice;
        private String suggestedPhotoSize;
        private String chosenPrintQuality;
        private String suggestedPrintQuality;

        public static OrderItemDTO from(OrderItem item) {
            OrderItemDTO dto = new OrderItemDTO();
            dto.id = item.getId();
            dto.imageUrl = item.getImageUrl() != null ? item.getImageUrl() : "";
            dto.photoSize = item.getPhotoSize() != null ? item.getPhotoSize() : "—";
            dto.quantity = item.getQuantity();
            dto.pricePerUnit = item.getPricePerUnit() != null ? item.getPricePerUnit() : BigDecimal.ZERO;
            dto.withFrame = item.isWithFrame();
            dto.frameId = item.getFrameId();
            dto.frameName = item.getFrameName();
            dto.frameImageUrl = item.getFrameImageUrl();
            dto.framePrice = item.getFramePrice() != null ? item.getFramePrice() : BigDecimal.ZERO;
            dto.studioPrintAdvice = item.getStudioPrintAdvice();
            dto.suggestedPhotoSize = item.getSuggestedPhotoSize();
            dto.chosenPrintQuality = item.getChosenPrintQuality();
            dto.suggestedPrintQuality = item.getSuggestedPrintQuality();
            return dto;
        }

        public Long getId() {
            return id;
        }

        public String getImageUrl() {
            return imageUrl;
        }

        public String getPhotoSize() {
            return photoSize;
        }

        public int getQuantity() {
            return quantity;
        }

        public BigDecimal getPricePerUnit() {
            return pricePerUnit;
        }

        public boolean isWithFrame() {
            return withFrame;
        }

        public Long getFrameId() {
            return frameId;
        }

        public String getFrameName() {
            return frameName;
        }

        public String getFrameImageUrl() {
            return frameImageUrl;
        }

        public BigDecimal getFramePrice() {
            return framePrice;
        }

        public String getStudioPrintAdvice() {
            return studioPrintAdvice;
        }

        public String getSuggestedPhotoSize() {
            return suggestedPhotoSize;
        }

        public String getChosenPrintQuality() {
            return chosenPrintQuality;
        }

        public String getSuggestedPrintQuality() {
            return suggestedPrintQuality;
        }
    }
}

package com.studiophoto.photoappbackend.notification;

import com.studiophoto.photoappbackend.booking.Booking;
import com.studiophoto.photoappbackend.booking.BookingStatus;
import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.order.Order;
import com.studiophoto.photoappbackend.order.OrderStatus;
import com.studiophoto.photoappbackend.order.RefundStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class UserNotificationService {

    private static final int READ_RETENTION_DAYS = 3;

    private final UserNotificationRepository repository;

    @Transactional
    public UserNotification create(User user, NotificationType type, String title, String body,
            Long relatedOrderId, Long relatedBookingId) {
        UserNotification notification = UserNotification.builder()
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .relatedOrderId(relatedOrderId)
                .relatedBookingId(relatedBookingId)
                .read(false)
                .build();
        return repository.save(notification);
    }

    @Transactional
    public List<UserNotificationDTO> listForUser(User user) {
        purgeExpiredReadForUser(user.getId());
        return repository.findByUserIdOrderByCreatedAtDesc(user.getId()).stream()
                .map(UserNotificationDTO::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public long countUnread(User user) {
        purgeExpiredReadForUser(user.getId());
        return repository.countByUserIdAndReadFalse(user.getId());
    }

    @Transactional
    public UserNotificationDTO markAsRead(Long notificationId, User user) {
        UserNotification notification = repository.findByIdAndUserId(notificationId, user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Notification introuvable."));
        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(LocalDateTime.now());
            notification = repository.save(notification);
        }
        return UserNotificationDTO.from(notification);
    }

    @Transactional
    public void delete(Long notificationId, User user) {
        UserNotification notification = repository.findByIdAndUserId(notificationId, user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Notification introuvable."));
        repository.delete(notification);
    }

    @Transactional
    public void purgeExpiredReadForUser(Integer userId) {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(READ_RETENTION_DAYS);
        repository.deleteReadOlderThan(userId, cutoff);
    }

    @Transactional
    public void purgeAllExpiredRead() {
        LocalDateTime cutoff = LocalDateTime.now().minusDays(READ_RETENTION_DAYS);
        repository.deleteAllReadOlderThan(cutoff);
    }

    // ── Événements commandes ───────────────────────────────────────────────

    public void notifyOrderCreated(Order order) {
        String amount = formatAmount(order.getTotalAmount());
        create(order.getUser(), NotificationType.ORDER_CREATED,
                "Commande enregistrée",
                "Votre commande #" + order.getId() + " a été créée pour un montant de " + amount
                        + ". Finalisez le paiement pour que nous la traitions.",
                order.getId(), null);
    }

    public void notifyPaymentUnderReview(Order order) {
        create(order.getUser(), NotificationType.PAYMENT_UNDER_REVIEW,
                "Paiement en vérification",
                "Nous avons bien reçu votre preuve de paiement pour la commande #" + order.getId()
                        + ". Notre équipe va la vérifier sous peu.",
                order.getId(), null);
    }

    public void notifyPaymentConfirmed(Order order) {
        create(order.getUser(), NotificationType.PAYMENT_CONFIRMED,
                "Paiement confirmé",
                "Bonne nouvelle ! Votre paiement pour la commande #" + order.getId()
                        + " (" + formatAmount(order.getTotalAmount())
                        + ") a été validé. Vos photos sont en cours de traitement.",
                order.getId(), null);
    }

    public void notifyOrderCompleted(Order order) {
        create(order.getUser(), NotificationType.ORDER_COMPLETED,
                "Commande terminée",
                "Votre commande #" + order.getId() + " est terminée."
                        + (order.getDeliveryType() != null && order.getDeliveryType().toLowerCase().contains("xpress")
                        ? " Vous serez contacté pour la livraison express."
                        : " Vous pouvez récupérer vos tirages ou attendre la livraison selon le mode choisi."),
                order.getId(), null);
    }

    public void notifyOrderCancelledByAdmin(Order order) {
        create(order.getUser(), NotificationType.ORDER_CANCELLED,
                "Commande annulée",
                "La commande #" + order.getId() + " a été annulée par le studio."
                        + " Contactez-nous si vous avez des questions.",
                order.getId(), null);
    }

    public void notifyOrderCancelledByCustomer(Order order) {
        create(order.getUser(), NotificationType.ORDER_CANCELLED_BY_YOU,
                "Annulation confirmée",
                "Vous avez annulé la commande #" + order.getId() + ".",
                order.getId(), null);
    }

    public void notifyCancellationRefused(User user, Long orderId, String reason) {
        String message = reason != null && !reason.isBlank()
                ? reason
                : "Votre demande d'annulation n'a pas pu être acceptée.";
        create(user, NotificationType.CANCELLATION_REFUSED,
                "Annulation refusée",
                "Commande #" + orderId + " : " + message,
                orderId, null);
    }

    public void notifyRefundPending(Order order) {
        String amount = formatAmount(order.getRefundAmount() != null
                ? order.getRefundAmount()
                : order.getTotalAmount());
        String reasonPart = order.getRefundReason() != null && !order.getRefundReason().isBlank()
                ? " Motif : " + order.getRefundReason()
                : "";
        create(order.getUser(), NotificationType.REFUND_PENDING,
                "Remboursement en cours",
                "Un remboursement de " + amount + " est en cours pour votre commande #" + order.getId() + "."
                        + reasonPart,
                order.getId(), null);
    }

    public void notifyRefundConfirmed(Order order) {
        String amount = formatAmount(order.getRefundAmount() != null
                ? order.getRefundAmount()
                : order.getTotalAmount());
        String refPart = order.getRefundReference() != null && !order.getRefundReference().isBlank()
                ? " Référence : " + order.getRefundReference() + "."
                : "";
        create(order.getUser(), NotificationType.REFUND_CONFIRMED,
                "Remboursement effectué",
                "Nous avons remboursé " + amount + " pour la commande #" + order.getId() + "." + refPart,
                order.getId(), null);
    }

    public void onOrderStatusUpdated(Order order, OrderStatus previousStatus, OrderStatus newStatus) {
        if (newStatus == OrderStatus.PROCESSING && previousStatus != OrderStatus.PROCESSING) {
            notifyPaymentConfirmed(order);
        } else if (newStatus == OrderStatus.COMPLETED) {
            notifyOrderCompleted(order);
        } else if (newStatus == OrderStatus.CANCELLED
                && order.getRefundStatus() != RefundStatus.REFUNDED) {
            notifyOrderCancelledByAdmin(order);
        }
    }

    // ── Réservations ───────────────────────────────────────────────────────

    public void onBookingStatusUpdated(Booking booking, BookingStatus previousStatus, BookingStatus newStatus) {
        if (newStatus == BookingStatus.CONFIRMED && previousStatus != BookingStatus.CONFIRMED) {
            create(booking.getUser(), NotificationType.BOOKING_CONFIRMED,
                    "Réservation confirmée",
                    "Votre réservation #" + booking.getId() + " est confirmée. À bientôt au studio !",
                    null, booking.getId());
        } else if (newStatus == BookingStatus.CANCELLED && previousStatus != BookingStatus.CANCELLED) {
            create(booking.getUser(), NotificationType.BOOKING_CANCELLED,
                    "Réservation annulée",
                    "Votre réservation #" + booking.getId() + " a été annulée.",
                    null, booking.getId());
        }
    }

    private String formatAmount(BigDecimal amount) {
        if (amount == null) {
            return "0 FCFA";
        }
        return amount.stripTrailingZeros().toPlainString() + " FCFA";
    }
}

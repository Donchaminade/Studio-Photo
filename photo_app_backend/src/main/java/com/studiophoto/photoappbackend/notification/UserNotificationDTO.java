package com.studiophoto.photoappbackend.notification;

import com.fasterxml.jackson.annotation.JsonFormat;

import java.time.LocalDateTime;

public class UserNotificationDTO {

    private Long id;
    private String type;
    private String title;
    private String body;
    private Long relatedOrderId;
    private Long relatedBookingId;
    private boolean read;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime readAt;

    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime createdAt;

    public static UserNotificationDTO from(UserNotification n) {
        UserNotificationDTO dto = new UserNotificationDTO();
        dto.id = n.getId();
        dto.type = n.getType().name();
        dto.title = n.getTitle();
        dto.body = n.getBody();
        dto.relatedOrderId = n.getRelatedOrderId();
        dto.relatedBookingId = n.getRelatedBookingId();
        dto.read = n.isRead();
        dto.readAt = n.getReadAt();
        dto.createdAt = n.getCreatedAt();
        return dto;
    }

    public Long getId() {
        return id;
    }

    public String getType() {
        return type;
    }

    public String getTitle() {
        return title;
    }

    public String getBody() {
        return body;
    }

    public Long getRelatedOrderId() {
        return relatedOrderId;
    }

    public Long getRelatedBookingId() {
        return relatedBookingId;
    }

    public boolean isRead() {
        return read;
    }

    public LocalDateTime getReadAt() {
        return readAt;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
}

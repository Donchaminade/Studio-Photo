package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class ActivityItemDTO {
    private String description;
    private LocalDateTime timestamp;
    private String icon;
    private String color;
    private String type; // e.g., "user", "order", "booking"
    private Long entityId; // The ID of the associated entity
}

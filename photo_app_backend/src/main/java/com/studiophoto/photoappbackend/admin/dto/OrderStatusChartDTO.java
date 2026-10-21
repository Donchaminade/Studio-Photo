package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class OrderStatusChartDTO {
    private List<String> labels; // e.g., "PENDING", "COMPLETED"
    private List<Long> data;     // e.g., 10, 50
    private List<String> backgroundColors; // e.g., "#FF6384", "#36A2EB"
}

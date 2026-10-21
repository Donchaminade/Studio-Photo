package com.studiophoto.photoappbackend.admin.dto;

import java.math.BigDecimal;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class DashboardStatsDTO {
    private long totalUsers;
    private long totalPhotos;
    private long totalPendingOrders;
    private BigDecimal totalRevenue;
    private BigDecimal averageOrderValue;
}

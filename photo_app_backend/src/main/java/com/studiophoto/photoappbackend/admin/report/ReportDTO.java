package com.studiophoto.photoappbackend.admin.report;

import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class ReportDTO {
    // Summary
    private long totalNewUsers;
    private long totalOrders;
    private long totalBookings;
    private BigDecimal totalRevenue;

    // Details
    private List<com.studiophoto.photoappbackend.order.Order> recentOrders;
    private List<com.studiophoto.photoappbackend.model.User> recentUsers;
    // ... more details can be added
}

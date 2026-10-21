package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class BookingStatusChartDTO {
    private List<String> labels; // e.g., "PENDING", "CONFIRMED"
    private List<Long> data;     // e.g., 5, 20
    private List<String> backgroundColors; // e.g., "#FFCE56", "#4BC0C0"
}

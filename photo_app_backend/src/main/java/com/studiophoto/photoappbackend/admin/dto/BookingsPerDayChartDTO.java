package com.studiophoto.photoappbackend.admin.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class BookingsPerDayChartDTO {
    private List<String> labels; // e.g., "2026-02-01", "2026-02-02"
    private List<Long> data;     // e.g., 3, 5
}

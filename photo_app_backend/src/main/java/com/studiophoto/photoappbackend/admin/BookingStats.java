package com.studiophoto.photoappbackend.admin;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class BookingStats {
    private long totalBookings;
    private long pendingBookings;
    private long confirmedBookings;
    private long todayBookings;
}

package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.booking.BookingStatus;
import com.studiophoto.photoappbackend.booking.BookingType;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
public class AdminBookingRequest {
    private Integer userId;
    private String title;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BookingType type;
    private BookingStatus status;
    private BigDecimal amount;
    private String notes;
}

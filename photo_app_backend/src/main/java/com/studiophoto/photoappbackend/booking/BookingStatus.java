package com.studiophoto.photoappbackend.booking;

public enum BookingStatus {
    PENDING("#f39c12"), // Orange
    CONFIRMED("#2ecc71"), // Green
    CANCELLED("#e74c3c"), // Red
    COMPLETED("#95a5a6"); // Gray

    private final String color;

    BookingStatus(String color) {
        this.color = color;
    }

    public String getColor() {
        return color;
    }
}

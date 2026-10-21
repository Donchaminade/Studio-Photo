package com.studiophoto.photoappbackend.order;

public enum OrderStatus {
    PENDING("En attente"),
    PENDING_PAYMENT("En attente de paiement"),
    PROCESSING("En traitement"),
    COMPLETED("Terminée"),
    CANCELLED("Annulée");

    private final String displayName;

    OrderStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
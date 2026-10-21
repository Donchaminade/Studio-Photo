package com.studiophoto.photoappbackend.order;

/**
 * Statut du remboursement manuel (USSD opérateur, confirmé par l'admin).
 */
public enum RefundStatus {
    NONE("Aucun"),
    REFUND_PENDING("Remboursement en cours"),
    REFUNDED("Remboursé");

    private final String displayName;

    RefundStatus(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}

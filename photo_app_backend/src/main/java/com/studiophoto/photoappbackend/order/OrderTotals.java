package com.studiophoto.photoappbackend.order;

import java.math.BigDecimal;
import java.util.List;

/**
 * Source unique du calcul de ligne / total commande (aligné app Flutter).
 * Express : +1500 FCFA si au plus {@value #EXPRESS_MAX_LINE_ITEMS} photos (lignes).
 */
public final class OrderTotals {

    public static final BigDecimal EXPRESS_FEE = new BigDecimal("1500");
    public static final int EXPRESS_MAX_LINE_ITEMS = 10;

    private OrderTotals() {
    }

    public static List<OrderStatus> confirmedPaidStatuses() {
        return List.of(OrderStatus.PROCESSING, OrderStatus.COMPLETED);
    }

    public static BigDecimal zeroIfNull(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    public static BigDecimal lineUnitTotal(BigDecimal printPrice, BigDecimal framePrice) {
        return zeroIfNull(printPrice).add(zeroIfNull(framePrice));
    }

    public static BigDecimal lineTotal(BigDecimal printPrice, BigDecimal framePrice, int quantity) {
        int qty = Math.max(quantity, 0);
        return lineUnitTotal(printPrice, framePrice).multiply(BigDecimal.valueOf(qty));
    }

    public static BigDecimal deliveryFee(boolean express, int lineItemCount) {
        if (express && lineItemCount > 0 && lineItemCount <= EXPRESS_MAX_LINE_ITEMS) {
            return EXPRESS_FEE;
        }
        return BigDecimal.ZERO;
    }

    public static BigDecimal orderTotal(BigDecimal subtotal, boolean express, int lineItemCount) {
        return zeroIfNull(subtotal).add(deliveryFee(express, lineItemCount));
    }
}

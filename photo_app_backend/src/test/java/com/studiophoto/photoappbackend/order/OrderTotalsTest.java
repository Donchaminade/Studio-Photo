package com.studiophoto.photoappbackend.order;

import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static org.junit.jupiter.api.Assertions.assertEquals;

class OrderTotalsTest {

    @Test
    void clientPays3500_fourPrints20x30PlusExpress() {
        // 4 × 500 FCFA (20x30) + Xpress 1500 = 3500 — cas réel client
        BigDecimal subtotal = OrderTotals.lineTotal(new BigDecimal("500"), BigDecimal.ZERO, 4);
        BigDecimal total = OrderTotals.orderTotal(subtotal, true, 4);
        assertEquals(0, new BigDecimal("3500").compareTo(total));
    }

    @Test
    void clientPays3500_printPlusFramePlusExpress() {
        // 500 (tirage) + 1500 (cadre) + 1500 (Xpress) = 3500
        BigDecimal subtotal = OrderTotals.lineTotal(new BigDecimal("500"), new BigDecimal("1500"), 1);
        BigDecimal total = OrderTotals.orderTotal(subtotal, true, 1);
        assertEquals(0, new BigDecimal("3500").compareTo(total));
    }

    @Test
    void expressIgnoredWhenMoreThanTenPhotos() {
        BigDecimal subtotal = OrderTotals.lineTotal(new BigDecimal("150"), BigDecimal.ZERO, 11);
        BigDecimal total = OrderTotals.orderTotal(subtotal, true, 11);
        assertEquals(0, new BigDecimal("1650").compareTo(total));
    }

    @Test
    void standardDeliveryHasNoFee() {
        BigDecimal subtotal = OrderTotals.lineTotal(new BigDecimal("150"), new BigDecimal("2000"), 1);
        BigDecimal total = OrderTotals.orderTotal(subtotal, false, 1);
        assertEquals(0, new BigDecimal("2150").compareTo(total));
    }
}

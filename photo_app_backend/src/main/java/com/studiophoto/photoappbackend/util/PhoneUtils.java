package com.studiophoto.photoappbackend.util;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * Normalisation des numéros (Togo +228 par défaut) pour inscription / connexion.
 */
public final class PhoneUtils {

    public static final String DEFAULT_DIAL_CODE = "+228";

    private PhoneUtils() {
    }

    public static String normalize(String raw) {
        if (raw == null) {
            return null;
        }
        String cleaned = raw.trim().replaceAll("[\\s.\\-()]", "");
        if (cleaned.isEmpty()) {
            return cleaned;
        }
        if (cleaned.startsWith("00")) {
            cleaned = "+" + cleaned.substring(2);
        }
        if (cleaned.startsWith("+")) {
            return cleaned;
        }
        if (cleaned.startsWith("228") && cleaned.length() >= 11) {
            return "+" + cleaned;
        }
        // 090123456 → +22890123456
        if (cleaned.startsWith("0") && cleaned.length() == 9 && cleaned.substring(1).matches("\\d{8}")) {
            return DEFAULT_DIAL_CODE + cleaned.substring(1);
        }
        // 90123456 (8 chiffres locaux)
        if (cleaned.matches("\\d{8}")) {
            return DEFAULT_DIAL_CODE + cleaned;
        }
        return cleaned;
    }

    /**
     * Variantes possibles en base (anciens comptes, saisies sans indicatif, etc.).
     */
    public static List<String> lookupVariants(String raw) {
        Set<String> variants = new LinkedHashSet<>();
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        String trimmed = raw.trim();
        variants.add(trimmed);

        String normalized = normalize(trimmed);
        if (!normalized.isBlank()) {
            variants.add(normalized);
        }

        if (normalized.startsWith("+228") && normalized.length() == 12) {
            String local = normalized.substring(4);
            variants.add(local);
            variants.add("228" + local);
            variants.add("0" + local);
        }

        return new ArrayList<>(variants);
    }
}

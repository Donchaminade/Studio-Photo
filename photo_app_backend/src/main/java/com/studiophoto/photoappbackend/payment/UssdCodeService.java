package com.studiophoto.photoappbackend.payment;

import com.studiophoto.photoappbackend.order.Order;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * Résout le code USSD marchand d'une commande sans jamais exposer les codes au
 * client en dehors du résultat final lié à une commande authentifiée.
 */
@Service
@RequiredArgsConstructor
public class UssdCodeService {

    // Valeurs par défaut (graine initiale). Modifiables ensuite depuis l'admin.
    public static final String DEFAULT_YAS_TEMPLATE = "*145*5*{amount}*1322683#";
    public static final String DEFAULT_MOOV_TEMPLATE = "*155*2*2*140425*140425*{amount}#";

    private final UssdMerchantConfigRepository repository;

    @Transactional
    public UssdMerchantConfig getOrCreateConfig() {
        return repository.findTopByOrderByIdAsc().orElseGet(() -> repository.save(
                UssdMerchantConfig.builder()
                        .yasTemplate(DEFAULT_YAS_TEMPLATE)
                        .moovTemplate(DEFAULT_MOOV_TEMPLATE)
                        .build()));
    }

    @Transactional
    public UssdMerchantConfig save(String yasTemplate, String moovTemplate) {
        UssdMerchantConfig config = getOrCreateConfig();
        if (yasTemplate != null && !yasTemplate.isBlank()) {
            config.setYasTemplate(yasTemplate.trim());
        }
        if (moovTemplate != null && !moovTemplate.isBlank()) {
            config.setMoovTemplate(moovTemplate.trim());
        }
        return repository.save(config);
    }

    /**
     * Construit le code USSD final pour une commande à partir de son moyen de
     * paiement et de son montant (tous deux issus du serveur).
     */
    public String resolveForOrder(Order order) {
        if (order == null) {
            throw new IllegalArgumentException("Commande introuvable.");
        }
        UssdMerchantConfig config = getOrCreateConfig();

        String method = order.getPaymentMethod() == null
                ? ""
                : order.getPaymentMethod().toLowerCase();

        String template = (method.contains("flooz") || method.contains("moov"))
                ? config.getMoovTemplate()
                : config.getYasTemplate();

        if (template == null || template.isBlank()) {
            template = (method.contains("flooz") || method.contains("moov"))
                    ? DEFAULT_MOOV_TEMPLATE
                    : DEFAULT_YAS_TEMPLATE;
        }

        return template.replace("{amount}", formatAmount(order.getTotalAmount()));
    }

    private String formatAmount(BigDecimal amount) {
        if (amount == null) {
            return "0";
        }
        return amount.setScale(0, RoundingMode.HALF_UP).toPlainString();
    }
}

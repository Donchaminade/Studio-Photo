package com.studiophoto.photoappbackend.payment;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Configuration sensible des codes USSD marchand (Togo).
 *
 * Stockée côté serveur uniquement : les codes ne sont JAMAIS embarqués dans
 * l'application mobile. Le client récupère le code final calculé via un
 * endpoint authentifié, lié à une commande dont le montant est connu du
 * serveur (empêche le détournement du code marchand et la falsification du
 * montant).
 *
 * Les modèles contiennent le marqueur {amount} remplacé par le montant de la
 * commande au moment de la génération.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "ussd_merchant_config")
public class UssdMerchantConfig {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Modèle USSD pour Yas / Mixx by Yas (Togocom). */
    @Column(length = 128)
    private String yasTemplate;

    /** Modèle USSD pour Flooz / Moov Money. */
    @Column(length = 128)
    private String moovTemplate;
}

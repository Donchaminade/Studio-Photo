package com.studiophoto.photoappbackend.order;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "order_items")
public class OrderItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @JsonBackReference
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @Column(nullable = false)
    private String imageUrl; // Can be a local path or a URL from user's album

    @Column(nullable = false)
    private String photoSize; // e.g., "10x15 cm"

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private BigDecimal pricePerUnit;

    @Builder.Default
    @Column(nullable = false)
    private boolean withFrame = false;

    private Long frameId;

    @Column(length = 128)
    private String frameName;

    /** Image du cadre choisi (snapshot pour le studio). */
    @Column(length = 512)
    private String frameImageUrl;

    @Builder.Default
    @Column(nullable = false)
    private BigDecimal framePrice = BigDecimal.ZERO;

    /** Conseil d'impression pour le studio (non affiché au client mobile). */
    @Column(length = 2000)
    private String studioPrintAdvice;

    /** Format catalogue conseillé si différent du choix client. */
    @Column(length = 64)
    private String suggestedPhotoSize;

    /** PERFECT, CORRECT ou TOO_SMALL — qualité du format choisi. */
    @Column(length = 16)
    private String chosenPrintQuality;

    /** Qualité du format conseillé (souvent PERFECT). */
    @Column(length = 16)
    private String suggestedPrintQuality;
}

package com.studiophoto.photoappbackend.dimension;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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
@Table(name = "dimensions")
public class Dimension {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name; // e.g., "9x13 cm"
    private BigDecimal price;
    private String title;
    private String description;
    private boolean isPopular;
    private String images; // Comma-separated image URLs

    /** Prix du cadre proposé pour ce format (null = pas de cadre). */
    private BigDecimal framePrice;
}

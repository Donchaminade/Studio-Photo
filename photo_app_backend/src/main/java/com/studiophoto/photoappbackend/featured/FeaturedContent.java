package com.studiophoto.photoappbackend.featured;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "featured_content")
public class FeaturedContent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String title; // Texte principal de la carte
    private String imageUrl; // URL de l'image de fond
    private String buttonText; // Texte du bouton
    private String buttonAction; // Action du bouton (par exemple, une URL ou un ID de route)

    private boolean active; // Pour activer/désactiver le contenu
    private int priority; // Pour ordonner si plusieurs contenus existent

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}

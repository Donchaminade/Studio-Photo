package com.studiophoto.photoappbackend.config;

import com.studiophoto.photoappbackend.dimension.Dimension;
import com.studiophoto.photoappbackend.dimension.DimensionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
public class DimensionDataInitializer implements CommandLineRunner {

    private final DimensionRepository dimensionRepository;

    @Override
    public void run(String... args) throws Exception {
        if (dimensionRepository.count() == 0) {
            // Utiliser les images existantes dans le dossier /uploads du backend comme placeholders
            List<String> placeholderImages = List.of(
                    "/uploads/51bc4427-68fb-4ee1-a483-8b9005c6684f-or.jpg",
                    "/uploads/52eadc05-e776-48b8-bc2d-b1897a5f6e11-WhatsApp_Image_2026-01-22_at_17.22.21.jpeg",
                    "/uploads/8cf1f2e0-c54e-4ef6-8aab-f9c01f903a55-mi.png",
                    "/uploads/c317213e-b9ef-4219-a51f-583bf2a6fb64-cafe-vrac_01.webp"
            );

            List<Dimension> dimensions = List.of(
                    Dimension.builder().name("9x13 cm").price(new BigDecimal("75")).images(placeholderImages.get(0)).title("Petit Format Classique").description("Idéal pour les albums photos ou les petits cadres.").isPopular(false).build(),
                    Dimension.builder().name("10x15 cm").price(new BigDecimal("150")).images(placeholderImages.get(1)).title("Format Standard").description("Le format le plus courant pour partager vos moments.").isPopular(true).build(),
                    Dimension.builder().name("13x18 cm").price(new BigDecimal("125")).images(placeholderImages.get(2)).title("Portrait Élégant").description("Un choix populaire pour les portraits et les photos de famille.").isPopular(true).build(),
                    Dimension.builder().name("15x21 cm").price(new BigDecimal("175")).images(placeholderImages.get(3)).title("Polyvalent et Pratique").description("Excellent pour la plupart des photos.").isPopular(false).build(),
                    Dimension.builder().name("20x25 cm").price(new BigDecimal("375")).images(placeholderImages.get(0)).title("Agrandissement Modéré").description("Mettez en valeur vos clichés préférés.").isPopular(true).build(),
                    Dimension.builder().name("20x30 cm").price(new BigDecimal("500")).images(placeholderImages.get(1)).title("Format A4 Photo").description("Le format classique pour une reproduction fidèle.").isPopular(false).build(),
                    Dimension.builder().name("24x30 cm").price(new BigDecimal("750")).images(placeholderImages.get(2)).title("Grand Format Équilibré").description("Une taille imposante sans être démesurée.").isPopular(false).build(),
                    Dimension.builder().name("30x40 cm").price(new BigDecimal("1250")).images(placeholderImages.get(3)).title("Galerie d'Art").description("Transformez vos photos en œuvres d'art.").isPopular(true).build(),
                    Dimension.builder().name("30x45 cm").price(new BigDecimal("1500")).images(placeholderImages.get(0)).title("Panorama Standard").description("Parfait pour les paysages ou les photos de groupe.").isPopular(false).build(),
                    Dimension.builder().name("30x90 cm").price(new BigDecimal("2000")).images(placeholderImages.get(1)).title("Bandeau Panoramique").description("Pour des vues panoramiques spectaculaires.").isPopular(false).build(),
                    Dimension.builder().name("40x50 cm").price(new BigDecimal("2500")).images(placeholderImages.get(2)).title("Affichage Mural").description("Impression grand format pour décorer un mur.").isPopular(false).build(),
                    Dimension.builder().name("40x60 cm").price(new BigDecimal("3250")).images(placeholderImages.get(3)).title("Impact Visuel Fort").description("Le choix des professionnels pour les expositions.").isPopular(false).build(),
                    Dimension.builder().name("50x60 cm").price(new BigDecimal("3750")).images(placeholderImages.get(0)).title("Très Grand Format").description("Pour immortaliser vos plus beaux souvenirs avec grandeur.").isPopular(false).build(),
                    Dimension.builder().name("60x90 cm").price(new BigDecimal("4500")).images(placeholderImages.get(1)).title("Poster Géant").description("La taille idéale pour les posters ou les affiches promotionnelles.").isPopular(false).build(),
                    Dimension.builder().name("60x120 cm").price(new BigDecimal("6250")).images(placeholderImages.get(2)).title("Immersion Maximale").description("La plus grande taille disponible pour une immersion totale.").isPopular(false).build()
            );
            dimensionRepository.saveAll(dimensions);
            log.info("Initialized {} dimensions with placeholder images from /uploads/ directory.", dimensions.size());
        }
    }
}

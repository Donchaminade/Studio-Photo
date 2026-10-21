package com.studiophoto.photoappbackend.featured;

import com.studiophoto.photoappbackend.storage.StorageService; // NEW
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
// @RequiredArgsConstructor // Removed because we will manually create
// constructor
public class FeaturedContentService {

    private final FeaturedContentRepository featuredContentRepository;
    private final StorageService storageService;
    private final com.studiophoto.photoappbackend.service.NotificationService notificationService;

    public FeaturedContentService(FeaturedContentRepository featuredContentRepository,
            StorageService storageService,
            com.studiophoto.photoappbackend.service.NotificationService notificationService) {
        this.featuredContentRepository = featuredContentRepository;
        this.storageService = storageService;
        this.notificationService = notificationService;
    }

    public Optional<FeaturedContent> getActiveFeaturedContent() {
        return featuredContentRepository.findFirstByActiveTrueOrderByPriorityAsc();
    }

    public List<FeaturedContent> getAllFeaturedContent() {
        return featuredContentRepository.findAll();
    }

    public Optional<FeaturedContent> getFeaturedContentById(Long id) {
        return featuredContentRepository.findById(id);
    }

    public FeaturedContent saveFeaturedContent(FeaturedContent featuredContent) {
        FeaturedContent saved = featuredContentRepository.save(featuredContent);
        notificationService.sendSyncNotification("FEATURED_UPDATED");
        return saved;
    }

    public void deleteFeaturedContent(Long id) {
        // Optionnel: Supprimer le fichier image associé
        featuredContentRepository.findById(id).ifPresent(content -> {
            if (content.getImageUrl() != null && !content.getImageUrl().isEmpty()) {
                // Extraire le nom du fichier de l'URL
                String filename = content.getImageUrl().substring(content.getImageUrl().lastIndexOf('/') + 1);
                storageService.delete(filename);
            }
        });
        featuredContentRepository.deleteById(id);
        notificationService.sendSyncNotification("FEATURED_UPDATED");
    }
}

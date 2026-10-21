package com.studiophoto.photoappbackend.promotion;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class PromotionService {

    private final PromotionRepository promotionRepository;
    private final com.studiophoto.photoappbackend.service.NotificationService notificationService;

    public List<Promotion> getAllActivePromotions() {
        return promotionRepository.findByActiveTrue();
    }

    public List<Promotion> getAllPromotions() {
        return promotionRepository.findAll();
    }

    public Optional<Promotion> getPromotionById(Long id) {
        return promotionRepository.findById(id);
    }

    public Promotion savePromotion(Promotion promotion) {
        Promotion saved = promotionRepository.save(promotion);
        notificationService.sendSyncNotification("PROMOTIONS_UPDATED");
        return saved;
    }

    public void deletePromotion(Long id) {
        promotionRepository.deleteById(id);
        notificationService.sendSyncNotification("PROMOTIONS_UPDATED");
    }
}

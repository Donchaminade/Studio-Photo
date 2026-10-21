package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.promotion.Promotion;
import com.studiophoto.photoappbackend.promotion.PromotionService;
import com.studiophoto.photoappbackend.storage.StorageService;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Optional;

@Controller
@RequestMapping("/admin/promotions")
// @RequiredArgsConstructor // Removed because we will manually create
// constructor
public class AdminPromotionController {

    private final PromotionService promotionService;
    private final StorageService storageService;

    public AdminPromotionController(PromotionService promotionService, StorageService storageService) {
        this.promotionService = promotionService;
        this.storageService = storageService;
    }

    @GetMapping
    public String promotionsManagement(Model model) {
        List<Promotion> promotions = promotionService.getAllPromotions();
        model.addAttribute("promotions", promotions);
        return "admin/promotions-management";
    }

    // Endpoint pour afficher le formulaire d'ajout/édition
    @GetMapping("/form")
    public String showPromotionForm(@RequestParam(value = "id", required = false) Long id, Model model) {
        Promotion promotion = id != null ? promotionService.getPromotionById(id).orElse(new Promotion())
                : new Promotion();
        model.addAttribute("promotion", promotion);
        return "admin/promotion-form";
    }

    // Endpoint pour sauvegarder une promotion
    @PostMapping("/save")
    public String savePromotion(@ModelAttribute Promotion promotion,
            @RequestParam(value = "file", required = false) MultipartFile file,
            RedirectAttributes redirectAttributes) {

        if (file != null && !file.isEmpty()) {
            // Supprimer l'ancienne image si elle existe et si on la remplace
            if (promotion.getId() != null && promotion.getImageUrl() != null && !promotion.getImageUrl().isEmpty()) {
                String oldFilename = promotion.getImageUrl().substring(promotion.getImageUrl().lastIndexOf('/') + 1);
                storageService.delete(oldFilename);
            }
            // Stocker la nouvelle image
            String filename = storageService.store(file);
            promotion.setImageUrl(storageService.getFileUrl(filename));
        } else if (promotion.getId() != null) {
            // Si c'est une mise à jour et pas de nouvelle image, conservez l'ancienne URL
            Optional<Promotion> existingPromotion = promotionService.getPromotionById(promotion.getId());
            existingPromotion.ifPresent(p -> promotion.setImageUrl(p.getImageUrl()));
        } else {
            // Si c'est une nouvelle promotion sans image
            redirectAttributes.addFlashAttribute("errorMessage", "Veuillez sélectionner une image pour la promotion.");
            return "redirect:/admin/promotions/form";
        }

        promotionService.savePromotion(promotion);
        redirectAttributes.addFlashAttribute("successMessage", "Promotion enregistrée avec succès !");
        return "redirect:/admin/promotions";
    }

    // Endpoint pour supprimer une promotion
    @PostMapping("/delete/{id}")
    @ResponseBody
    public ResponseEntity<Void> deletePromotion(@PathVariable Long id) {
        promotionService.deletePromotion(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/bulk-delete")
    @ResponseBody
    public ResponseEntity<Void> bulkDelete(@RequestBody List<Long> ids) {
        ids.forEach(promotionService::deletePromotion);
        return ResponseEntity.noContent().build();
    }
}

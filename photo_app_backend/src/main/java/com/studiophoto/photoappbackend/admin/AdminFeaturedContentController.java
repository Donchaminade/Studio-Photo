package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.featured.FeaturedContent;
import com.studiophoto.photoappbackend.featured.FeaturedContentService;
import com.studiophoto.photoappbackend.storage.StorageService; // NEW
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile; // NEW
import org.springframework.web.servlet.mvc.support.RedirectAttributes; // NEW

import java.util.List;
import java.util.Optional; // NEW

@Controller
@RequestMapping("/admin/featured-content")
// @RequiredArgsConstructor // Removed because we will manually create
// constructor
public class AdminFeaturedContentController {

    private final FeaturedContentService featuredContentService;
    private final StorageService storageService; // NEW

    public AdminFeaturedContentController(FeaturedContentService featuredContentService,
            StorageService storageService) {
        this.featuredContentService = featuredContentService;
        this.storageService = storageService;
    }

    @GetMapping
    public String featuredContentManagement(Model model) {
        List<FeaturedContent> featuredContents = featuredContentService.getAllFeaturedContent();
        model.addAttribute("featuredContents", featuredContents);
        return "admin/featured-content-management";
    }

    // Endpoint pour afficher le formulaire d'ajout/édition
    @GetMapping("/form")
    public String showFeaturedContentForm(@RequestParam(value = "id", required = false) Long id, Model model) {
        FeaturedContent featuredContent = id != null
                ? featuredContentService.getFeaturedContentById(id).orElse(new FeaturedContent())
                : new FeaturedContent();
        model.addAttribute("featuredContent", featuredContent);
        return "admin/featured-content-form";
    }

    // Endpoint pour sauvegarder un contenu
    @PostMapping("/save")
    public String saveFeaturedContent(@ModelAttribute FeaturedContent featuredContent,
            @RequestParam(value = "file", required = false) MultipartFile file, // NEW
            RedirectAttributes redirectAttributes) { // NEW

        if (file != null && !file.isEmpty()) {
            // Supprimer l'ancienne image si elle existe et si on la remplace
            if (featuredContent.getId() != null && featuredContent.getImageUrl() != null
                    && !featuredContent.getImageUrl().isEmpty()) {
                String oldFilename = featuredContent.getImageUrl()
                        .substring(featuredContent.getImageUrl().lastIndexOf('/') + 1);
                storageService.delete(oldFilename);
            }
            // Stocker la nouvelle image
            String filename = storageService.store(file);
            featuredContent.setImageUrl(storageService.getFileUrl(filename)); // Sauvegarde l'URL publique
        } else if (featuredContent.getId() != null) {
            // Si c'est une mise à jour et pas de nouvelle image, conservez l'ancienne URL
            Optional<FeaturedContent> existingContent = featuredContentService
                    .getFeaturedContentById(featuredContent.getId());
            existingContent.ifPresent(p -> featuredContent.setImageUrl(p.getImageUrl()));
        } else {
            // Si c'est un nouveau contenu sans image
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Veuillez sélectionner une image pour le contenu mis en avant.");
            return "redirect:/admin/featured-content/form"; // Ou affichez une erreur sur le formulaire
        }

        featuredContentService.saveFeaturedContent(featuredContent);
        redirectAttributes.addFlashAttribute("successMessage", "Contenu mis en avant enregistré avec succès !");
        return "redirect:/admin/featured-content";
    }

    // Endpoint pour supprimer un contenu
    @PostMapping("/delete/{id}")
    @ResponseBody
    public ResponseEntity<Void> deleteFeaturedContent(@PathVariable Long id) {
        featuredContentService.deleteFeaturedContent(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/bulk-delete")
    @ResponseBody
    public ResponseEntity<Void> bulkDelete(@RequestBody List<Long> ids) {
        ids.forEach(featuredContentService::deleteFeaturedContent);
        return ResponseEntity.noContent().build();
    }
}

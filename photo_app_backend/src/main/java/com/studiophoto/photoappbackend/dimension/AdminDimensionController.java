package com.studiophoto.photoappbackend.dimension;

import com.studiophoto.photoappbackend.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin/dimensions")
@RequiredArgsConstructor
public class AdminDimensionController {

    private final DimensionService dimensionService;
    private final StorageService storageService;

    @GetMapping
    public String listDimensions(Model model) {
        model.addAttribute("dimensions", dimensionService.findAll());
        return "admin/dimensions/list";
    }

    @GetMapping("/add")
    public String showAddForm(Model model) {
        model.addAttribute("dimension", new Dimension());
        model.addAttribute("pageTitle", "Ajouter une nouvelle dimension");
        return "admin/dimensions/form";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Long id, Model model, RedirectAttributes redirectAttributes) {
        try {
            Dimension dimension = dimensionService.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Dimension non trouvée avec l'ID : " + id));
            model.addAttribute("dimension", dimension);
            model.addAttribute("pageTitle", "Modifier la dimension");
            return "admin/dimensions/form";
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/admin/dimensions";
        }
    }

    @PostMapping("/save")
    public String saveDimension(@ModelAttribute("dimension") Dimension dimension,
                                @RequestParam(name = "files", required = false) MultipartFile[] files,
                                RedirectAttributes redirectAttributes) {
        try {
            // Si de nouveaux fichiers sont téléchargés, ils remplacent les anciens.
            if (files != null && files.length > 0 && !files[0].isEmpty()) {
                List<String> newImageUrls = Arrays.stream(files)
                        .filter(file -> !file.isEmpty())
                        .map(storageService::store)
                        .map(storageService::getFileUrl)
                        .collect(Collectors.toList());

                dimension.setImages(String.join(",", newImageUrls));
            }
            // Si aucun nouveau fichier n'est téléchargé, le champ 'dimension.images' (qui est
            // peuplé par le champ caché dans le formulaire) est conservé.

            dimensionService.save(dimension);
            redirectAttributes.addFlashAttribute("successMessage", "La dimension a été enregistrée avec succès !");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Erreur lors de l'enregistrement de la dimension: " + e.getMessage());
        }
        return "redirect:/admin/dimensions";
    }

    @GetMapping("/delete/{id}")
    public String deleteDimension(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            dimensionService.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "La dimension a été supprimée avec succès.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Erreur lors de la suppression de la dimension.");
        }
        return "redirect:/admin/dimensions";
    }
}

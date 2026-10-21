package com.studiophoto.photoappbackend.frame;

import com.studiophoto.photoappbackend.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin/frames")
@RequiredArgsConstructor
public class AdminPhotoFrameController {

    private final PhotoFrameService photoFrameService;
    private final StorageService storageService;

    @GetMapping
    public String listFrames(Model model) {
        model.addAttribute("frames", photoFrameService.findAll());
        return "admin/frames/list";
    }

    @GetMapping("/add")
    public String showAddForm(Model model) {
        model.addAttribute("frame", PhotoFrame.builder().active(true).sortOrder(0).build());
        model.addAttribute("pageTitle", "Ajouter un cadre");
        return "admin/frames/form";
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(@PathVariable("id") Long id, Model model, RedirectAttributes redirectAttributes) {
        try {
            PhotoFrame frame = photoFrameService.findById(id)
                    .orElseThrow(() -> new IllegalArgumentException("Cadre non trouvé avec l'ID : " + id));
            model.addAttribute("frame", frame);
            model.addAttribute("pageTitle", "Modifier le cadre");
            return "admin/frames/form";
        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/admin/frames";
        }
    }

    @PostMapping("/save")
    public String saveFrame(@ModelAttribute("frame") PhotoFrame frame,
                            @RequestParam(name = "files", required = false) MultipartFile[] files,
                            RedirectAttributes redirectAttributes) {
        try {
            if (files != null && files.length > 0 && !files[0].isEmpty()) {
                List<String> newImageUrls = Arrays.stream(files)
                        .filter(file -> !file.isEmpty())
                        .map(storageService::store)
                        .map(storageService::getFileUrl)
                        .collect(Collectors.toList());
                frame.setImages(String.join(",", newImageUrls));
            }
            photoFrameService.save(frame);
            redirectAttributes.addFlashAttribute("successMessage", "Le cadre a été enregistré avec succès !");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Erreur lors de l'enregistrement du cadre : " + e.getMessage());
        }
        return "redirect:/admin/frames";
    }

    @GetMapping("/delete/{id}")
    public String deleteFrame(@PathVariable("id") Long id, RedirectAttributes redirectAttributes) {
        try {
            photoFrameService.deleteById(id);
            redirectAttributes.addFlashAttribute("successMessage", "Le cadre a été supprimé avec succès.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage", "Erreur lors de la suppression du cadre.");
        }
        return "redirect:/admin/frames";
    }
}

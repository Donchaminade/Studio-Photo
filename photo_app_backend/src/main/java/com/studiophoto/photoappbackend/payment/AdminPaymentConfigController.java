package com.studiophoto.photoappbackend.payment;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/admin/payment-config")
@RequiredArgsConstructor
public class AdminPaymentConfigController {

    private final UssdCodeService ussdCodeService;

    @GetMapping
    public String showConfig(Model model) {
        model.addAttribute("config", ussdCodeService.getOrCreateConfig());
        return "admin/payment/config";
    }

    @PostMapping("/save")
    public String saveConfig(@RequestParam("yasTemplate") String yasTemplate,
                             @RequestParam("moovTemplate") String moovTemplate,
                             RedirectAttributes redirectAttributes) {
        try {
            ussdCodeService.save(yasTemplate, moovTemplate);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Les codes USSD ont été mis à jour avec succès.");
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Erreur lors de l'enregistrement : " + e.getMessage());
        }
        return "redirect:/admin/payment-config";
    }
}

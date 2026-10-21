package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import com.studiophoto.photoappbackend.model.User;

@Controller
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    @GetMapping("/login")
    public String login() {
        return "admin/login";
    }

    @GetMapping("/dashboard")
    public String dashboard() {
        return "admin/dashboard";
    }

    @GetMapping("/profile")
    public String profile(@AuthenticationPrincipal User user, Model model) {
        model.addAttribute("user", user);
        return "admin/profile";
    }

    @GetMapping("/profile/edit")
    public String editProfile(@AuthenticationPrincipal User user, Model model) {
        model.addAttribute("user", user);
        return "admin/profile-edit";
    }

    @PostMapping("/profile/edit")
    public String updateProfile(@AuthenticationPrincipal User currentUser,
            @RequestParam String firstname,
            @RequestParam String lastname,
            @RequestParam String email,
            @RequestParam(required = false) String phone,
            RedirectAttributes redirectAttributes) {

        User user = userRepository.findById(currentUser.getId()).orElseThrow();
        user.setFirstname(firstname);
        user.setLastname(lastname);
        user.setEmail(email);
        user.setPhone(phone);

        userRepository.save(user);

        // Update the principal in the session (optional but recommended)
        currentUser.setFirstname(firstname);
        currentUser.setLastname(lastname);
        currentUser.setEmail(email);
        currentUser.setPhone(phone);

        redirectAttributes.addFlashAttribute("successMessage", "Profil mis à jour avec succès !");
        return "redirect:/admin/profile";
    }

    @GetMapping("/profile/change-password")
    public String changePasswordPage(@AuthenticationPrincipal User user, Model model) {
        model.addAttribute("user", user);
        return "admin/change-password";
    }

    @PostMapping("/profile/change-password")
    public String changePassword(@AuthenticationPrincipal User currentUser,
            @RequestParam String currentPassword,
            @RequestParam String newPassword,
            @RequestParam String confirmPassword,
            RedirectAttributes redirectAttributes) {

        if (!passwordEncoder.matches(currentPassword, currentUser.getPassword())) {
            redirectAttributes.addFlashAttribute("errorMessage", "Le mot de passe actuel est incorrect.");
            return "redirect:/admin/profile/change-password";
        }

        if (!newPassword.equals(confirmPassword)) {
            redirectAttributes.addFlashAttribute("errorMessage", "Les nouveaux mots de passe ne correspondent pas.");
            return "redirect:/admin/profile/change-password";
        }

        User user = userRepository.findById(currentUser.getId()).orElseThrow();
        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);

        // Update the principal's password in session
        currentUser.setPassword(user.getPassword());

        redirectAttributes.addFlashAttribute("successMessage", "Mot de passe changé avec succès !");
        return "redirect:/admin/profile";
    }
}

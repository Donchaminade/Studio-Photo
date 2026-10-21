package com.studiophoto.photoappbackend;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PrivacyPolicyController {

    @GetMapping({"/privacy", "/politique-de-confidentialite"})
    public String privacyPolicy() {
        return "privacy";
    }
}

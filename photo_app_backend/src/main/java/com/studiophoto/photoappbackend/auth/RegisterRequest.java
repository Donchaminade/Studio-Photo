package com.studiophoto.photoappbackend.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class RegisterRequest {

    @NotBlank(message = "Le prénom est obligatoire")
    private String firstname;

    private String lastname;

    @NotBlank(message = "L'email est obligatoire")
    @Email(message = "Format d'email invalide")
    private String email;

    @NotBlank(message = "Le mot de passe est obligatoire")
    @Size(min = 6, message = "Le mot de passe doit contenir au moins 6 caractères")
    private String password;

    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    private String phone;

    @NotBlank(message = "Le code PIN est obligatoire")
    @Size(min = 4, max = 4, message = "Le code PIN doit contenir exactement 4 chiffres")
    @Pattern(regexp = "\\d{4}", message = "Le code PIN doit contenir uniquement 4 chiffres")
    private String pin;
}

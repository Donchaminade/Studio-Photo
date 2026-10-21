package com.studiophoto.photoappbackend.admin.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactInfoRequest {
    private Long id; // For updates

    @NotBlank(message = "L'adresse est requise")
    private String address;

    @NotBlank(message = "Le numéro de téléphone est requis")
    private String phoneNumber;

    private String whatsappNumber;

    @NotBlank(message = "L'email est requis")
    @Email(message = "L'email doit être une adresse email valide")
    private String email;

    @NotBlank(message = "Les horaires d'ouverture sont requis")
    private String openingHours;

    private String facebookUrl;
    private String twitterUrl;
    private String instagramUrl;
    private String linkedinUrl;
}

package com.studiophoto.photoappbackend.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class VerifyPinRequest {
    @NotBlank(message = "L'identifiant (email ou téléphone) est obligatoire")
    private String identifier;

    @NotBlank(message = "Le code PIN est obligatoire")
    @Size(min = 4, max = 4, message = "Le code PIN doit contenir exactement 4 chiffres")
    private String pin;
}

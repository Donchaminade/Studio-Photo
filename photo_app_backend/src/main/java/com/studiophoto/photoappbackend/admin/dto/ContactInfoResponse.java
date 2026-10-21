package com.studiophoto.photoappbackend.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ContactInfoResponse {
    private Long id;
    private String address;
    private String phoneNumber;
    private String whatsappNumber;
    private String email;
    private String openingHours;
    private String facebookUrl;
    private String twitterUrl;
    private String instagramUrl;
    private String linkedinUrl;
}

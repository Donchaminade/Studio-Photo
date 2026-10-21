package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.dto.ContactInfoRequest;
import com.studiophoto.photoappbackend.admin.dto.ContactInfoResponse;
import com.studiophoto.photoappbackend.model.ContactInfo;
import com.studiophoto.photoappbackend.repository.ContactInfoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AdminContactInfoService {

    private final ContactInfoRepository contactInfoRepository;

    public ContactInfoResponse getContactInfo() {
        Optional<ContactInfo> contactInfo = contactInfoRepository.findTopByOrderByIdAsc();
        return contactInfo.map(this::mapToContactInfoResponse).orElse(null);
    }

    public ContactInfoResponse saveContactInfo(ContactInfoRequest request) {
        ContactInfo contactInfo;
        if (request.getId() != null) {
            contactInfo = contactInfoRepository.findById(request.getId())
                    .orElse(new ContactInfo());
        } else {
            // If no ID is provided, check if there's any existing contact info
            // For this application, we'll assume there's only one ContactInfo entry
            contactInfo = contactInfoRepository.findTopByOrderByIdAsc().orElse(new ContactInfo());
        }

        contactInfo.setAddress(request.getAddress());
        contactInfo.setPhoneNumber(request.getPhoneNumber());
        contactInfo.setWhatsappNumber(request.getWhatsappNumber());
        contactInfo.setEmail(request.getEmail());
        contactInfo.setOpeningHours(request.getOpeningHours());
        contactInfo.setFacebookUrl(request.getFacebookUrl());
        contactInfo.setTwitterUrl(request.getTwitterUrl());
        contactInfo.setInstagramUrl(request.getInstagramUrl());
        contactInfo.setLinkedinUrl(request.getLinkedinUrl());

        return mapToContactInfoResponse(contactInfoRepository.save(contactInfo));
    }

    private ContactInfoResponse mapToContactInfoResponse(ContactInfo contactInfo) {
        return ContactInfoResponse.builder()
                .id(contactInfo.getId())
                .address(contactInfo.getAddress())
                .phoneNumber(contactInfo.getPhoneNumber())
                .whatsappNumber(contactInfo.getWhatsappNumber())
                .email(contactInfo.getEmail())
                .openingHours(contactInfo.getOpeningHours())
                .facebookUrl(contactInfo.getFacebookUrl())
                .twitterUrl(contactInfo.getTwitterUrl())
                .instagramUrl(contactInfo.getInstagramUrl())
                .linkedinUrl(contactInfo.getLinkedinUrl())
                .build();
    }
}

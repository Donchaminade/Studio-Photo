package com.studiophoto.photoappbackend;

import com.studiophoto.photoappbackend.admin.AdminContactInfoService;
import com.studiophoto.photoappbackend.admin.dto.ContactInfoResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;



import com.studiophoto.photoappbackend.admin.AdminContactInfoService;
import com.studiophoto.photoappbackend.admin.dto.ContactInfoResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/public/contact-info")
@RequiredArgsConstructor
public class ContactInfoController {

    private final AdminContactInfoService contactInfoService;

    @GetMapping
    public ResponseEntity<ContactInfoResponse> getContactInfo() {
        ContactInfoResponse contactInfo = contactInfoService.getContactInfo();
        if (contactInfo != null) {
            return ResponseEntity.ok(contactInfo);
        }
        return ResponseEntity.notFound().build();
    }
}

package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.dto.ContactInfoRequest;
import com.studiophoto.photoappbackend.admin.dto.ContactInfoResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

@Controller
@RequestMapping("/admin/contact-info")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')") // Ensure only ADMINs can access contact info management
public class AdminContactInfoController {

    private final AdminContactInfoService contactInfoService;

    // Render contact info management page
    @GetMapping
    public String contactInfoManagementPage(Model model) {
        ContactInfoResponse contactInfo = contactInfoService.getContactInfo();
        model.addAttribute("contactInfo", contactInfo != null ? contactInfo : new ContactInfoResponse());
        return "admin/contact-info-management";
    }

    // API endpoints for Contact Info CRUD

    @GetMapping("/api")
    @ResponseBody
    public ResponseEntity<ContactInfoResponse> getContactInfoApi() {
        ContactInfoResponse contactInfo = contactInfoService.getContactInfo();
        if (contactInfo != null) {
            return ResponseEntity.ok(contactInfo);
        }
        return ResponseEntity.notFound().build();
    }

    @PostMapping("/api")
    @ResponseBody
    public ResponseEntity<ContactInfoResponse> saveContactInfoApi(@Valid @RequestBody ContactInfoRequest request) {
        ContactInfoResponse savedContactInfo = contactInfoService.saveContactInfo(request);
        return ResponseEntity.ok(savedContactInfo);
    }
}

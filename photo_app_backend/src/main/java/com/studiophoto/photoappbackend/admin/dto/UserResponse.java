package com.studiophoto.photoappbackend.admin.dto;

import com.studiophoto.photoappbackend.model.Role;
import com.studiophoto.photoappbackend.model.Status; // Import new Status enum
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime; // Import LocalDateTime

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserResponse {
    private Integer id;
    private String firstname;
    private String lastname;
    private String email;
    private Role role;
    private Status status; // New field
    private String phone; // New field
    private String pin; // New field
    private LocalDateTime createdAt; // New field
    private LocalDateTime lastLogin; // New field
}

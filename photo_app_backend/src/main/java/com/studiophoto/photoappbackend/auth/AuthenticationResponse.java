package com.studiophoto.photoappbackend.auth;

import com.studiophoto.photoappbackend.model.Role;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AuthenticationResponse {
    private String token;
    private String refreshToken;
    private Integer id;
    private String firstname;
    private String lastname;
    private String email;
    private String phone;
    private Role role;
}

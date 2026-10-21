package com.studiophoto.photoappbackend.config;

import com.studiophoto.photoappbackend.repository.UserRepository;
import com.studiophoto.photoappbackend.util.PhoneUtils;
import com.studiophoto.photoappbackend.storage.StorageProperties;
import com.studiophoto.photoappbackend.storage.StorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Optional;

@Configuration
@RequiredArgsConstructor
public class ApplicationConfig {

    private final UserRepository repository;

    @Bean
    public UserDetailsService userDetailsService() {
        return username -> {
            if (username == null || username.isBlank()) {
                throw new UsernameNotFoundException("Identifiant vide");
            }
            String trimmed = username.trim();
            Optional<com.studiophoto.photoappbackend.model.User> user;
            if (trimmed.contains("@")) {
                user = repository.findByEmail(trimmed);
            } else {
                user = repository.findFirstByPhoneIn(PhoneUtils.lookupVariants(trimmed));
            }
            return user.orElseThrow(
                    () -> new UsernameNotFoundException("User not found with identifier: " + trimmed));
        };
    }

    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider authProvider = new DaoAuthenticationProvider();
        authProvider.setUserDetailsService(userDetailsService());
        authProvider.setPasswordEncoder(passwordEncoder());
        return authProvider;
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    // NEW: Initialize StorageService on startup
    @Bean
    CommandLineRunner init(StorageService storageService) {
        return (args) -> {
            storageService.init();
        };
    }

    // NEW: Configure resource handler for uploaded files
    @Bean
    public WebMvcConfigurer webMvcConfigurer(StorageProperties storageProperties) {
        return new WebMvcConfigurer() {
            @Override
            public void addResourceHandlers(ResourceHandlerRegistry registry) {
                // Handler pour les images uploadées
                registry.addResourceHandler("/uploads/**")
                        .addResourceLocations("file:" + storageProperties.getLocation() + "/");
            }
        };
    }
}

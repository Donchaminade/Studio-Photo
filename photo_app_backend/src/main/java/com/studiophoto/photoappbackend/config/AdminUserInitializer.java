package com.studiophoto.photoappbackend.config;

import com.studiophoto.photoappbackend.model.Role;
import com.studiophoto.photoappbackend.model.Status; // Import Status enum
import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class AdminUserInitializer implements CommandLineRunner {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    private static final String LEGACY_ADMIN_EMAIL = "admin@example.com";
    /** Compte admin de test / ops (créé au boot s'il n'existe pas). */
    private static final String TEST_ADMIN_EMAIL = "admin@photopicon.com";
    private static final String TEST_ADMIN_PASSWORD = "AdminTest2026!";

    @Override
    public void run(String... args) throws Exception {
        ensureLegacyAdminActive();
        ensureTestAdmin();
    }

    private void ensureLegacyAdminActive() {
        userRepository.findByEmail(LEGACY_ADMIN_EMAIL).ifPresentOrElse(
            existingAdmin -> {
                if (existingAdmin.getStatus() != Status.ACTIVE) {
                    existingAdmin.setStatus(Status.ACTIVE);
                    userRepository.save(existingAdmin);
                    log.info("Existing admin user updated to ACTIVE status: {}", existingAdmin.getEmail());
                }
            },
            () -> {
                var admin = User.builder()
                        .firstname("Admin")
                        .lastname("User")
                        .email(LEGACY_ADMIN_EMAIL)
                        .password(passwordEncoder.encode("adminpassword"))
                        .role(Role.ADMIN)
                        .status(Status.ACTIVE)
                        .build();
                userRepository.save(admin);
                log.info("Default admin user created: {}", LEGACY_ADMIN_EMAIL);
            }
        );
    }

    private void ensureTestAdmin() {
        userRepository.findByEmail(TEST_ADMIN_EMAIL).ifPresentOrElse(
            existing -> {
                boolean dirty = false;
                if (existing.getStatus() != Status.ACTIVE) {
                    existing.setStatus(Status.ACTIVE);
                    dirty = true;
                }
                if (existing.getRole() != Role.ADMIN) {
                    existing.setRole(Role.ADMIN);
                    dirty = true;
                }
                if (dirty) {
                    userRepository.save(existing);
                    log.info("Test admin ensured ACTIVE/ADMIN: {}", TEST_ADMIN_EMAIL);
                }
            },
            () -> {
                var admin = User.builder()
                        .firstname("Admin")
                        .lastname("Picon")
                        .email(TEST_ADMIN_EMAIL)
                        .password(passwordEncoder.encode(TEST_ADMIN_PASSWORD))
                        .phone("0600000001")
                        .pin("0000")
                        .role(Role.ADMIN)
                        .status(Status.ACTIVE)
                        .build();
                userRepository.save(admin);
                log.info("Test admin user created: {} / (password in COMMANDES_REDEPLOY.md)", TEST_ADMIN_EMAIL);
            }
        );
    }
}

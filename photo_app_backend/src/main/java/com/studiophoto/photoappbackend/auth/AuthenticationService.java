package com.studiophoto.photoappbackend.auth;

import com.studiophoto.photoappbackend.model.Role;
import com.studiophoto.photoappbackend.model.Status;
import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.repository.UserRepository;
import com.studiophoto.photoappbackend.security.JwtService;
import com.studiophoto.photoappbackend.service.ActivityService;
import com.studiophoto.photoappbackend.util.PhoneUtils;
import io.jsonwebtoken.Claims;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final AuthenticationManager authenticationManager;
    private final ActivityService activityService;

    public AuthenticationResponse register(RegisterRequest request) {
        boolean emailExists = userRepository.existsByEmail(request.getEmail());
        String normalizedPhone = PhoneUtils.normalize(request.getPhone());
        boolean phoneExists = PhoneUtils.lookupVariants(request.getPhone()).stream()
                .anyMatch(userRepository::existsByPhone);

        if (emailExists && phoneExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'adresse email et le numéro de téléphone sont déjà utilisés.");
        } else if (emailExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cette adresse email est déjà utilisée.");
        } else if (phoneExists) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Ce numéro de téléphone est déjà utilisé.");
        }
        String firstname = request.getFirstname().trim();
        String lastname = request.getLastname() != null ? request.getLastname().trim() : "";
        if (lastname.isBlank()) {
            lastname = firstname;
        }

        var user = User.builder()
                .firstname(firstname)
                .lastname(lastname)
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .phone(normalizedPhone)
                .pin(request.getPin()) // PIN is no longer hashed
                .role(Role.USER)
                .status(Status.ACTIVE) // Default to ACTIVE to allow immediate login
                .build();

        var savedUser = userRepository.save(user);

        activityService.logActivity(savedUser.getEmail(), "REGISTER", "Nouvelle inscription via API");

        return toAuthResponse(savedUser);
    }

    public AuthenticationResponse authenticate(LoginRequest request) {
        String identifier = request.getEmail() != null && !request.getEmail().isBlank()
                ? request.getEmail().trim()
                : request.getPhone() != null ? request.getPhone().trim() : null;

        if (identifier == null || identifier.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "L'email ou le numéro de téléphone doit être fourni.");
        }

        User user = resolveUserByIdentifier(identifier)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Email/Téléphone ou mot de passe incorrect."));

        if (!user.isEnabled()) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Votre compte n'est pas actif. Contactez le studio Photo.");
        }

        // JWT utilise toujours l'email comme identifiant (voir User.getUsername())
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            user.getEmail(),
                            request.getPassword()));
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Email/Téléphone ou mot de passe incorrect.");
        }

        activityService.logActivity(user.getEmail(), "LOGIN", "Connexion réussie");

        return toAuthResponse(user);
    }

    public AuthenticationResponse refresh(String refreshToken) {
        if (refreshToken == null || refreshToken.isBlank() || !jwtService.isRefreshToken(refreshToken)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Votre session a expiré. Reconnectez-vous.");
        }
        String username;
        try {
            username = jwtService.extractUsername(refreshToken);
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Votre session a expiré. Reconnectez-vous.");
        }
        User user = userRepository.findByEmail(username)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                        "Votre session a expiré. Reconnectez-vous."));
        if (!user.isEnabled() || !jwtService.isTokenValid(refreshToken, user)) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Votre session a expiré. Reconnectez-vous.");
        }
        return toAuthResponse(user);
    }

    private AuthenticationResponse toAuthResponse(User user) {
        return AuthenticationResponse.builder()
                .token(jwtService.generateToken(user))
                .refreshToken(jwtService.generateRefreshToken(user))
                .id(user.getId())
                .firstname(user.getFirstname())
                .lastname(user.getLastname())
                .email(user.getEmail())
                .phone(user.getPhone())
                .role(user.getRole())
                .build();
    }

    public String verifyPinForPasswordReset(String identifier, String pin) {
        Optional<User> userOpt = resolveUserByIdentifier(identifier);

        if (userOpt.isEmpty()) {
            if (identifier.contains("@")) {
                throw new RuntimeException("L'adresse email saisie est incorrecte ou n'existe pas.");
            } else {
                throw new RuntimeException("Le numéro de téléphone saisi est incorrect ou n'existe pas.");
            }
        }

        User user = userOpt.get();

        // Plain text PIN comparison as requested by the user
        if (user.getPin() == null || !user.getPin().equals(pin)) {
            // If the user wants to know if BOTH are wrong, we can only say it here if we
            // know the ID was right but PIN wrong.
            // But if they asked "clairement", we say it's the PIN.
            throw new RuntimeException("Le code secret (PIN) saisi est incorrect.");
        }

        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("type", "password-reset");

        // Generate a token with a 15-minute expiration
        return jwtService.generateToken(extraClaims, user, 1000 * 60 * 15);
    }

    public void resetPassword(String token, String newPassword) {
        final String username; // This could be email or phone
        try {
            username = jwtService.extractUsername(token);
        } catch (Exception e) {
            throw new RuntimeException("Lien de réinitialisation invalide ou expiré.");
        }

        User user = resolveUserByIdentifier(username)
                .orElseThrow(() -> new RuntimeException("Utilisateur non trouvé."));

        final Claims claims = jwtService.extractAllClaims(token);
        final String tokenType = claims.get("type", String.class);

        if (!"password-reset".equals(tokenType) || !jwtService.isTokenValid(token, user)) {
            throw new RuntimeException("Jeton de réinitialisation invalide ou expiré.");
        }

        user.setPassword(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    private Optional<User> resolveUserByIdentifier(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return Optional.empty();
        }
        String trimmed = identifier.trim();
        if (trimmed.contains("@")) {
            return userRepository.findByEmail(trimmed);
        }
        return userRepository.findFirstByPhoneIn(PhoneUtils.lookupVariants(trimmed));
    }
}

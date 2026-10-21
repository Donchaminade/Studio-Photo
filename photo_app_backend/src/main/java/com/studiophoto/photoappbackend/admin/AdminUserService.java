package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.dto.UserRequest;
import com.studiophoto.photoappbackend.admin.dto.UserResponse;
import com.studiophoto.photoappbackend.model.Role;
import com.studiophoto.photoappbackend.model.Status; // Import Status enum
import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.booking.BookingRepository;
import com.studiophoto.photoappbackend.notification.UserNotificationRepository;
import com.studiophoto.photoappbackend.order.OrderRepository;
import com.studiophoto.photoappbackend.repository.UserRepository;
import com.studiophoto.photoappbackend.service.ActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.extern.slf4j.Slf4j;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AdminUserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final OrderRepository orderRepository;
    private final BookingRepository bookingRepository;
    private final UserNotificationRepository userNotificationRepository;
    private final ActivityService activityService;

    private String getCurrentAdminEmail() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }

    public com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO getUserActivityChartData(Integer userId) {
        List<String> labels = new java.util.ArrayList<>();
        List<java.math.BigDecimal> data = new java.util.ArrayList<>();
        List<com.studiophoto.photoappbackend.order.OrderStatus> revenueStatuses = java.util.Arrays.asList(
                com.studiophoto.photoappbackend.order.OrderStatus.COMPLETED,
                com.studiophoto.photoappbackend.order.OrderStatus.PROCESSING);

        java.time.YearMonth currentMonth = java.time.YearMonth.now();
        for (int i = 5; i >= 0; i--) {
            java.time.YearMonth month = currentMonth.minusMonths(i);
            labels.add(month.getMonth().name());

            java.time.LocalDateTime start = month.atDay(1).atStartOfDay();
            java.time.LocalDateTime end = month.atEndOfMonth().atTime(23, 59, 59);

            java.math.BigDecimal monthlyRev = orderRepository.sumUserRevenueBetween(userId, revenueStatuses, start, end);
            data.add(monthlyRev != null ? monthlyRev : java.math.BigDecimal.ZERO);
        }

        long totalOrders = orderRepository.countOrdersByUserAndStatusIn(userId, revenueStatuses);
        java.math.BigDecimal totalRevenue = orderRepository.sumTotalRevenueByUserAndStatusIn(userId, revenueStatuses);
        if (totalRevenue == null) totalRevenue = java.math.BigDecimal.ZERO;

        return com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO.builder()
                .labels(labels)
                .data(data)
                .totalOrders(totalOrders)
                .totalRevenue(totalRevenue)
                .build();
    }

    public List<UserResponse> getAllUsers() {
        return userRepository.findAll().stream()
                .map(this::mapToUserResponse)
                .collect(Collectors.toList());
    }

    public Optional<UserResponse> getUserById(Integer id) {
        return userRepository.findById(id)
                .map(this::mapToUserResponse);
    }

    public UserResponse createUser(UserRequest request) {
        // Check if user with the same email already exists
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new IllegalStateException("Un utilisateur avec l'email " + request.getEmail() + " existe déjà.");
        }

        var user = User.builder()
                .firstname(request.getFirstname())
                .lastname(request.getLastname())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .role(request.getRole())
                .status(request.getStatus() != null ? request.getStatus() : Status.PENDING) // Use request status or
                                                                                            // default
                .phone(request.getPhone())
                .pin(request.getPin())
                .build();
        UserResponse response = mapToUserResponse(userRepository.save(user));
        activityService.logActivity(getCurrentAdminEmail(), "USER_CREATE", "Création de l'utilisateur: " + user.getEmail());
        return response;
    }

    public Optional<UserResponse> updateUser(Integer id, UserRequest request) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setFirstname(request.getFirstname());
                    user.setLastname(request.getLastname());
                    user.setEmail(request.getEmail());
                    user.setRole(request.getRole());
                    user.setStatus(request.getStatus()); // Update status
                    user.setPhone(request.getPhone()); // Update phone
                    user.setPin(request.getPin()); // Update pin

                    // Only update password if a new one is provided
                    if (request.getPassword() != null && !request.getPassword().isEmpty()) {
                        user.setPassword(passwordEncoder.encode(request.getPassword()));
                    }
                    UserResponse response = mapToUserResponse(userRepository.save(user));
                    activityService.logActivity(getCurrentAdminEmail(), "USER_UPDATE", "Modification de l'utilisateur ID: " + id);
                    return response;
                });
    }

    /**
     * Suppression admin sûre pour la prod studio photo :
     * - soft-delete (INACTIVE) si commandes ou réservations existent (historique conservé)
     * - hard-delete si aucun historique commercial (après nettoyage des notifications)
     */
    @Transactional
    public Optional<Map<String, Object>> deleteUser(Integer id) {
        log.info("Tentative de suppression de l'utilisateur ID: {}", id);
        return userRepository.findById(id).map(user -> {
            String currentAdminEmail = getCurrentAdminEmail();
            if (user.getEmail() != null && user.getEmail().equalsIgnoreCase(currentAdminEmail)) {
                throw new IllegalStateException("Vous ne pouvez pas supprimer votre propre compte.");
            }
            if (user.getRole() == Role.ADMIN) {
                long otherActiveAdmins = userRepository.findAll().stream()
                        .filter(u -> u.getRole() == Role.ADMIN)
                        .filter(u -> u.getStatus() == Status.ACTIVE)
                        .filter(u -> !u.getId().equals(id))
                        .count();
                if (otherActiveAdmins == 0) {
                    throw new IllegalStateException(
                            "Impossible de supprimer le dernier administrateur actif.");
                }
            }

            boolean hasOrders = !orderRepository.findByUserIdOrderByCreatedAtDesc(id).isEmpty();
            boolean hasBookings = !bookingRepository.findByUser(user).isEmpty();
            Map<String, Object> result = new HashMap<>();
            result.put("userId", id);
            result.put("email", user.getEmail());

            if (hasOrders || hasBookings) {
                user.setStatus(Status.INACTIVE);
                userRepository.save(user);
                // Empêche la reconnexion JWT tant que le statut reste INACTIVE (isEnabled=false).
                log.info("Utilisateur {} désactivé (soft-delete) — commandes/réservations conservées", id);
                activityService.logActivity(currentAdminEmail, "USER_SOFT_DELETE",
                        "Désactivation de l'utilisateur (historique conservé): " + user.getEmail());
                result.put("mode", "soft");
                result.put("message",
                        "Compte désactivé. Les commandes et réservations ont été conservées ; l'utilisateur ne peut plus se connecter.");
                return result;
            }

            // Aucun historique commercial : suppression définitive après nettoyage des FK.
            userNotificationRepository.deleteByUserId(id);
            userRepository.delete(user);
            log.info("Utilisateur {} supprimé définitivement (hard-delete)", id);
            activityService.logActivity(currentAdminEmail, "USER_DELETE",
                    "Suppression définitive de l'utilisateur: " + result.get("email"));
            result.put("mode", "hard");
            result.put("message", "Utilisateur supprimé définitivement.");
            return result;
        });
    }

    public Optional<UserResponse> resetUserPassword(Integer id, String newPassword) {
        return userRepository.findById(id)
                .map(user -> {
                    // Generate a new password if null or empty, otherwise use provided
                    String passwordToEncode = (newPassword == null || newPassword.isEmpty()) ? generateRandomPassword()
                            : newPassword;
                    user.setPassword(passwordEncoder.encode(passwordToEncode));
                    return mapToUserResponse(userRepository.save(user));
                });
    }

    public Optional<UserResponse> changeUserStatus(Integer id, Status newStatus) {
        return userRepository.findById(id)
                .map(user -> {
                    user.setStatus(newStatus);
                    return mapToUserResponse(userRepository.save(user));
                });
    }

    private UserResponse mapToUserResponse(User user) {
        return UserResponse.builder()
                .id(user.getId())
                .firstname(user.getFirstname())
                .lastname(user.getLastname())
                .email(user.getEmail())
                .role(user.getRole())
                .status(user.getStatus()) // Include status
                .phone(user.getPhone()) // Include phone
                .pin(user.getPin()) // Include pin
                .createdAt(user.getCreatedAt()) // Include createdAt
                .lastLogin(user.getLastLogin()) // Include lastLogin
                .build();
    }

    // A simple method to generate a random password (for auto-generation)
    private String generateRandomPassword() {
        // In a real application, consider a more robust random password generator
        return "Temp" + System.nanoTime();
    }
}

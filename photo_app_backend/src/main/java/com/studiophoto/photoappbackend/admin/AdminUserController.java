package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.dto.UserRequest;
import com.studiophoto.photoappbackend.admin.dto.UserResponse;
import com.studiophoto.photoappbackend.model.Role;
import com.studiophoto.photoappbackend.model.Status; // Import Status
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')") // Ensure only ADMINs can access user management
public class AdminUserController {

    private final AdminUserService adminUserService;

    // Render user management page
    @GetMapping
    public String userManagementPage(Model model) {
        model.addAttribute("roles", Role.values()); // Pass roles to the frontend for dropdown
        // Assuming you might want to pass statuses as well
        model.addAttribute("statuses", Status.values());
        return "admin/user-management";
    }

    // API endpoints for user CRUD

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ResponseBody
    public Map<String, String> handleValidationExceptions(MethodArgumentNotValidException ex) {
        Map<String, String> errors = new HashMap<>();
        ex.getBindingResult().getAllErrors().forEach((error) -> {
            String fieldName = ((FieldError) error).getField();
            String errorMessage = error.getDefaultMessage();
            errors.put(fieldName, errorMessage);
        });
        return errors;
    }

    @ExceptionHandler(IllegalStateException.class)
    public ResponseEntity<Map<String, String>> handleIllegalStateException(IllegalStateException ex) {
        Map<String, String> error = new HashMap<>();
        error.put("message", ex.getMessage());
        return new ResponseEntity<>(error, HttpStatus.CONFLICT);
    }

    @GetMapping("/api")
    @ResponseBody
    public ResponseEntity<List<UserResponse>> getAllUsers() {
        return ResponseEntity.ok(adminUserService.getAllUsers());
    }

    @GetMapping("/api/datatable")
    @ResponseBody
    public Map<String, Object> getUsersDatatable(
            @RequestParam int draw,
            @RequestParam int start,
            @RequestParam int length,
            @RequestParam(name = "search[value]", defaultValue = "") String searchValue,
            @RequestParam(name = "order[0][column]", defaultValue = "0") int orderColumn,
            @RequestParam(name = "order[0][dir]", defaultValue = "asc") String orderDir,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) String status) {

        List<UserResponse> allUsers = adminUserService.getAllUsers();

        // Filter
        List<UserResponse> filteredUsers = allUsers.stream()
                .filter(user -> {
                    // Search term filter
                    boolean matchesSearch = searchValue.isEmpty() ||
                            (user.getFirstname() != null
                                    && user.getFirstname().toLowerCase().contains(searchValue.toLowerCase()))
                            ||
                            (user.getLastname() != null
                                    && user.getLastname().toLowerCase().contains(searchValue.toLowerCase()))
                            ||
                            (user.getEmail() != null
                                    && user.getEmail().toLowerCase().contains(searchValue.toLowerCase()));

                    // Role filter
                    boolean matchesRole = role == null || role.isEmpty() ||
                            (user.getRole() != null && user.getRole().name().equals(role));

                    // Status filter
                    boolean matchesStatus = status == null || status.isEmpty() ||
                            (user.getStatus() != null && user.getStatus().name().equals(status));

                    return matchesSearch && matchesRole && matchesStatus;
                })
                .collect(Collectors.toList());

        // Sort (Simple implementation for standard columns)
        // In a real app, this would be handled better, but here we keep the stream
        // approach

        // Paging
        int totalFiltered = filteredUsers.size();
        int toIndex = Math.min(start + length, totalFiltered);
        List<UserResponse> pagedUsers = (start < totalFiltered) ? filteredUsers.subList(start, toIndex) : List.of();

        Map<String, Object> response = new HashMap<>();
        response.put("draw", draw);
        response.put("recordsTotal", allUsers.size());
        response.put("recordsFiltered", totalFiltered);
        response.put("data", pagedUsers);

        return response;
    }

    @GetMapping("/api/{id}")
    @ResponseBody
    public ResponseEntity<UserResponse> getUserById(@PathVariable Integer id) {
        return adminUserService.getUserById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping("/api/{id}/activity-chart")
    @ResponseBody
    public ResponseEntity<com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO> getUserActivityChart(@PathVariable Integer id) {
        return ResponseEntity.ok(adminUserService.getUserActivityChartData(id));
    }

    @PostMapping("/api")
    @ResponseBody
    public ResponseEntity<UserResponse> createUser(@Valid @RequestBody UserRequest request) {
        // Password is required for creation
        if (request.getPassword() == null || request.getPassword().isEmpty()) {
            return ResponseEntity.badRequest().build(); // Or a more specific error
        }
        UserResponse newUser = adminUserService.createUser(request);
        return new ResponseEntity<>(newUser, HttpStatus.CREATED);
    }

    @PutMapping("/api/{id}")
    @ResponseBody
    public ResponseEntity<UserResponse> updateUser(@PathVariable Integer id, @Valid @RequestBody UserRequest request) {
        // Password is optional for update, so no check here
        return adminUserService.updateUser(id, request)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @DeleteMapping("/api/{id}")
    @ResponseBody
    public ResponseEntity<?> deleteUser(@PathVariable Integer id) {
        return adminUserService.deleteUser(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/api/bulk-delete")
    @ResponseBody
    public ResponseEntity<?> bulkDeleteUsers(@RequestBody List<Integer> ids) {
        List<Map<String, Object>> results = new java.util.ArrayList<>();
        for (Integer id : ids) {
            adminUserService.deleteUser(id).ifPresent(results::add);
        }
        Map<String, Object> body = new HashMap<>();
        body.put("deleted", results.size());
        body.put("results", results);
        body.put("message", results.size() + " utilisateur(s) traité(s). Les comptes avec historique ont été désactivés.");
        return ResponseEntity.ok(body);
    }

    // New API endpoints for user actions

    // Endpoint for user statistics for stat cards
    @GetMapping("/api/stats")
    @ResponseBody
    public Map<String, Long> getUsersStats() {
        long totalUsers = adminUserService.getAllUsers().size();
        // These will need actual implementation using repository queries later
        long activeUsers = adminUserService.getAllUsers().stream().filter(u -> u.getStatus() == Status.ACTIVE).count();
        long adminUsers = adminUserService.getAllUsers().stream().filter(u -> u.getRole() == Role.ADMIN).count();
        // New users in last 7 days (placeholder)
        long newUsersLast7Days = adminUserService.getAllUsers().stream()
                .filter(u -> u.getCreatedAt() != null && u.getCreatedAt().isAfter(LocalDateTime.now().minusDays(7)))
                .count();

        Map<String, Long> stats = new HashMap<>();
        stats.put("totalUsers", totalUsers);
        stats.put("activeUsers", activeUsers);
        stats.put("adminUsers", adminUsers);
        stats.put("newUsers", newUsersLast7Days);
        return stats;
    }

    @PostMapping("/api/{id}/reset-password")
    @ResponseBody
    public ResponseEntity<UserResponse> resetPassword(@PathVariable Integer id,
            @RequestBody Map<String, String> payload) {
        String newPassword = payload.get("password");
        return adminUserService.resetUserPassword(id, newPassword)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/api/{id}/activate")
    @ResponseBody
    public ResponseEntity<UserResponse> activateUser(@PathVariable Integer id) {
        return adminUserService.changeUserStatus(id, Status.ACTIVE)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @PostMapping("/api/{id}/deactivate")
    @ResponseBody
    public ResponseEntity<UserResponse> deactivateUser(@PathVariable Integer id) {
        return adminUserService.changeUserStatus(id, Status.INACTIVE)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    // Assuming a simple payload for password reset, could be a dedicated DTO
    public static class PasswordResetRequest {
        private String password;

        // getters and setters
        public String getPassword() {
            return password;
        }

        public void setPassword(String password) {
            this.password = password;
        }
    }
}

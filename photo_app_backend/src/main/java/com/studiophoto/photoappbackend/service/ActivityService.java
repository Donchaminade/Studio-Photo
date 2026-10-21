package com.studiophoto.photoappbackend.service;

import com.studiophoto.photoappbackend.model.UserActivity;
import com.studiophoto.photoappbackend.repository.UserActivityRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ActivityService {

    private final UserActivityRepository userActivityRepository;
    private final HttpServletRequest request;

    public void logActivity(String email, String action, String details) {
        String ipAddress = request.getRemoteAddr();
        UserActivity activity = UserActivity.builder()
                .email(email)
                .action(action)
                .details(details)
                .ipAddress(ipAddress)
                .build();
        userActivityRepository.save(activity);
    }

    public List<UserActivity> getAllActivities() {
        return userActivityRepository.findAllByOrderByTimestampDesc();
    }
}

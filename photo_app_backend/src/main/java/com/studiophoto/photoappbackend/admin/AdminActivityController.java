package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.model.UserActivity;
import com.studiophoto.photoappbackend.service.ActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;

@Controller
@RequestMapping("/admin/events")
@RequiredArgsConstructor
public class AdminActivityController {

    private final ActivityService activityService;

    @GetMapping
    public String eventsPage(Model model) {
        List<UserActivity> activities = activityService.getAllActivities();
        model.addAttribute("activities", activities);
        return "admin/events";
    }
}

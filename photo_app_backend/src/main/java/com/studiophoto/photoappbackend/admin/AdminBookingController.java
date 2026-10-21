package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.booking.BookingService;
import com.studiophoto.photoappbackend.repository.UserRepository;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import java.util.Arrays;
import java.util.List;

@Controller
@RequestMapping("/admin/bookings")
public class AdminBookingController {

    private final BookingService bookingService;
    private final UserRepository userRepository;

    public AdminBookingController(BookingService bookingService, UserRepository userRepository) {
        this.bookingService = bookingService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public String bookingsManagement(Model model) {
        model.addAttribute("users", userRepository.findAll()); // Pour le choix de l'utilisateur dans les filtres et
                                                               // formulaires
        return "admin/bookings-management";
    }
}

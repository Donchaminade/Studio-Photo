package com.studiophoto.photoappbackend.booking;

import com.studiophoto.photoappbackend.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/bookings")
@RequiredArgsConstructor
public class BookingController {

    private final BookingService bookingService;

    @GetMapping
    public ResponseEntity<List<Booking>> getAllBookings(@AuthenticationPrincipal User currentUser) {
        // Pour l'API mobile, on ne devrait probablement montrer que les réservations de l'utilisateur connecté
        return ResponseEntity.ok(bookingService.getBookingsByUser(currentUser.getId()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Booking> getBookingById(@PathVariable Long id, @AuthenticationPrincipal User currentUser) {
        // S'assurer que l'utilisateur ne peut voir que ses propres réservations
        return bookingService.getBookingById(id)
                .filter(booking -> booking.getUser().getId().equals(currentUser.getId()))
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ResponseEntity<Booking> createBooking(@RequestBody Booking booking, @AuthenticationPrincipal User currentUser) {
        // Assigner l'utilisateur connecté à la réservation
        booking.setUser(currentUser);
        return ResponseEntity.ok(bookingService.createBooking(booking));
    }

    // L'API mobile pourrait aussi avoir besoin de modifier un booking, mais avec des restrictions
    @PutMapping("/{id}")
    public ResponseEntity<Booking> updateBooking(@PathVariable Long id, @RequestBody Booking booking, @AuthenticationPrincipal User currentUser) {
        // S'assurer que l'utilisateur ne peut modifier que ses propres réservations
        return bookingService.getBookingById(id)
                .filter(existingBooking -> existingBooking.getUser().getId().equals(currentUser.getId()))
                .map(existingBooking -> ResponseEntity.ok(bookingService.updateBooking(id, booking)))
                .orElse(ResponseEntity.notFound().build());
    }

    // L'API mobile pourrait avoir un endpoint pour annuler une réservation
    @PostMapping("/{id}/cancel")
    public ResponseEntity<Booking> cancelBooking(@PathVariable Long id, @AuthenticationPrincipal User currentUser) {
        return bookingService.getBookingById(id)
                .filter(booking -> booking.getUser().getId().equals(currentUser.getId()))
                .map(booking -> ResponseEntity.ok(bookingService.updateBookingStatus(id, BookingStatus.CANCELLED)))
                .orElse(ResponseEntity.notFound().build());
    }
}

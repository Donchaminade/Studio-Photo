package com.studiophoto.photoappbackend.booking;

import com.studiophoto.photoappbackend.model.User;
import com.studiophoto.photoappbackend.notification.UserNotificationService;
import com.studiophoto.photoappbackend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class BookingService {

    private final BookingRepository bookingRepository;
    private final UserRepository userRepository; // Pour vérifier l'existence de l'utilisateur
    private final UserNotificationService userNotificationService;

    public List<Booking> getAllBookings() {
        return bookingRepository.findAll();
    }

    public Optional<Booking> getBookingById(Long id) {
        return bookingRepository.findById(id);
    }

    public List<Booking> getBookingsByUser(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));
        return bookingRepository.findByUser(user);
    }

    public Booking createBooking(Booking booking) {
        // Optionnel: Ajouter des validations métier (ex: chevauchement de rendez-vous)
        // Assurez-vous que l'utilisateur existe
        userRepository.findById(booking.getUser().getId())
                .orElseThrow(() -> new IllegalArgumentException("Utilisateur non trouvé"));

        // Statut par défaut si non fourni
        if (booking.getStatus() == null) {
            booking.setStatus(BookingStatus.PENDING);
        }
        return bookingRepository.save(booking);
    }

    public Booking updateBooking(Long id, Booking updatedBooking) {
        return bookingRepository.findById(id)
                .map(existingBooking -> {
                    existingBooking.setTitle(updatedBooking.getTitle());
                    existingBooking.setDescription(updatedBooking.getDescription());
                    existingBooking.setStartTime(updatedBooking.getStartTime());
                    existingBooking.setEndTime(updatedBooking.getEndTime());
                    existingBooking.setStatus(updatedBooking.getStatus());
                    existingBooking.setNotes(updatedBooking.getNotes());
                    existingBooking.setUpdatedAt(LocalDateTime.now());
                    return bookingRepository.save(existingBooking);
                })
                .orElseThrow(() -> new IllegalArgumentException("Réservation non trouvée avec l'ID : " + id));
    }

    public void deleteBooking(Long id) {
        bookingRepository.deleteById(id);
    }

    public Booking updateBookingStatus(Long id, BookingStatus newStatus) {
        return bookingRepository.findById(id)
                .map(booking -> {
                    BookingStatus previousStatus = booking.getStatus();
                    booking.setStatus(newStatus);
                    booking.setUpdatedAt(LocalDateTime.now());
                    Booking saved = bookingRepository.save(booking);
                    userNotificationService.onBookingStatusUpdated(saved, previousStatus, newStatus);
                    return saved;
                })
                .orElseThrow(() -> new IllegalArgumentException("Réservation non trouvée avec l'ID : " + id));
    }

    public void saveBooking(Booking booking) {
    }

    public com.studiophoto.photoappbackend.admin.BookingStats getBookingStats() {
        long totalBookings = bookingRepository.count();
        long pendingBookings = bookingRepository.countByStatus(BookingStatus.PENDING);
        long confirmedBookings = bookingRepository.countByStatus(BookingStatus.CONFIRMED);
        long todayBookings = bookingRepository.countByStartTimeBetween(LocalDateTime.now().withHour(0).withMinute(0),
                LocalDateTime.now().withHour(23).withMinute(59));

        return com.studiophoto.photoappbackend.admin.BookingStats.builder()
                .totalBookings(totalBookings)
                .pendingBookings(pendingBookings)
                .confirmedBookings(confirmedBookings)
                .todayBookings(todayBookings)
                .build();
    }

    public Map<String, Object> getBookingDataTable(int draw, int start, int length, String searchValue,
            int orderColumn, String orderDir, String status, String dateRange, Long userId) {

        // Define column names for sorting
        String[] columnNames = { "user", "title", "startTime", "startTime", "duration", "type", "status", "amount",
                "createdAt" };

        // Build sorting
        Sort.Direction direction = Sort.Direction.fromString(orderDir);
        Sort sort = Sort.by(direction, columnNames[orderColumn]);

        // Build Pageable object
        Pageable pageable = PageRequest.of(start / length, length, sort);

        // Build Specifications for filtering
        Specification<Booking> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            // Global search
            if (StringUtils.hasText(searchValue)) {
                String likePattern = "%" + searchValue.toLowerCase() + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("title")), likePattern),
                        cb.like(cb.lower(root.get("notes")), likePattern),
                        cb.like(cb.lower(root.get("user").get("firstname")), likePattern),
                        cb.like(cb.lower(root.get("user").get("lastname")), likePattern),
                        cb.like(cb.lower(root.get("user").get("email")), likePattern)));
            }

            // Status filter
            if (StringUtils.hasText(status)) {
                predicates.add(cb.equal(root.get("status"), BookingStatus.valueOf(status)));
            }

            // Date range filter
            if (StringUtils.hasText(dateRange)) {
                LocalDateTime now = LocalDateTime.now();
                switch (dateRange) {
                    case "today":
                        predicates.add(cb.between(root.get("startTime"), now.withHour(0).withMinute(0),
                                now.withHour(23).withMinute(59)));
                        break;
                    case "tomorrow":
                        LocalDateTime tomorrow = now.plusDays(1);
                        predicates.add(cb.between(root.get("startTime"), tomorrow.withHour(0).withMinute(0),
                                tomorrow.withHour(23).withMinute(59)));
                        break;
                    case "this_week":
                        LocalDateTime startOfWeek = now.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
                                .withHour(0).withMinute(0);
                        LocalDateTime endOfWeek = now.with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)).withHour(23)
                                .withMinute(59);
                        predicates.add(cb.between(root.get("startTime"), startOfWeek, endOfWeek));
                        break;
                    case "next_week":
                        LocalDateTime nextWeekStart = now.plusWeeks(1)
                                .with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).withHour(0).withMinute(0);
                        LocalDateTime nextWeekEnd = now.plusWeeks(1)
                                .with(TemporalAdjusters.nextOrSame(DayOfWeek.SUNDAY)).withHour(23).withMinute(59);
                        predicates.add(cb.between(root.get("startTime"), nextWeekStart, nextWeekEnd));
                        break;
                    case "this_month":
                        predicates
                                .add(cb.between(root.get("startTime"), now.withDayOfMonth(1).withHour(0).withMinute(0),
                                        now.with(TemporalAdjusters.lastDayOfMonth()).withHour(23).withMinute(59)));
                        break;
                }
            }

            if (userId != null) {
                predicates.add(cb.equal(root.get("user").get("id"), userId));
            }

            // Force fetch user details to avoid "Non assigné" in admin table due to Lazy
            // Loading
            if (query.getResultType() != Long.class && query.getResultType() != long.class) {
                root.fetch("user", JoinType.LEFT);
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Booking> bookingsPage = bookingRepository.findAll(spec, pageable);

        Map<String, Object> response = new HashMap<>();
        response.put("draw", draw);
        response.put("recordsTotal", bookingRepository.count()); // Total records without filtering
        response.put("recordsFiltered", bookingsPage.getTotalElements()); // Total records after filtering
        response.put("data", bookingsPage.getContent()); // Data for the current page

        return response;
    }

    public List<Booking> getBookingsForCalendar(LocalDateTime start, LocalDateTime end) {
        Specification<Booking> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (start != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("startTime"), start));
            }
            if (end != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("endTime"), end));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
        return bookingRepository.findAll(spec);
    }
}

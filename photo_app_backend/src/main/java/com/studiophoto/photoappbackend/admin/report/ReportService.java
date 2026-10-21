package com.studiophoto.photoappbackend.admin.report;

import com.studiophoto.photoappbackend.order.OrderRepository;
import com.studiophoto.photoappbackend.order.OrderStatus;
import com.studiophoto.photoappbackend.repository.UserRepository;
import com.studiophoto.photoappbackend.booking.BookingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    private final BookingRepository bookingRepository;

    public ReportDTO generateReport(LocalDateTime startDate, LocalDateTime endDate) {
        // --- Summary Statistics ---
        long totalNewUsers = userRepository.countByCreatedAtBetween(startDate, endDate);
        long totalOrders = orderRepository.countByCreatedAtBetween(startDate, endDate);
        long totalBookings = bookingRepository.countByStartTimeBetween(startDate, endDate);

        List<OrderStatus> completedOrProcessing = Arrays.asList(OrderStatus.COMPLETED, OrderStatus.PROCESSING);
        BigDecimal totalRevenue = orderRepository.sumTotalAmountByStatusInAndCreatedAtBetween(
                completedOrProcessing, startDate, endDate);
        if (totalRevenue == null) {
            totalRevenue = BigDecimal.ZERO;
        }

        // --- Detailed Data (example) ---
        // For a full report, you'd fetch more detailed data like:
        List<com.studiophoto.photoappbackend.order.Order> recentOrders = orderRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(startDate, endDate);
        List<com.studiophoto.photoappbackend.model.User> recentUsers = userRepository.findByCreatedAtBetweenOrderByCreatedAtDesc(startDate, endDate);


        return ReportDTO.builder()
                .totalNewUsers(totalNewUsers)
                .totalOrders(totalOrders)
                .totalBookings(totalBookings)
                .totalRevenue(totalRevenue)
                .recentOrders(recentOrders)
                .recentUsers(recentUsers)
                .build();
    }
}

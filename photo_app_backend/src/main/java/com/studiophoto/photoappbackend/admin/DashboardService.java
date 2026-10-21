package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.dto.DashboardStatsDTO;
import com.studiophoto.photoappbackend.order.OrderItemRepository;
import com.studiophoto.photoappbackend.order.OrderRepository;
import com.studiophoto.photoappbackend.order.OrderStatus;
import com.studiophoto.photoappbackend.order.OrderTotals;
import com.studiophoto.photoappbackend.repository.UserRepository;
import com.studiophoto.photoappbackend.booking.BookingRepository;
import com.studiophoto.photoappbackend.booking.BookingStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.Arrays;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DashboardService {

    private final UserRepository userRepository;
    private final OrderItemRepository orderItemRepository;
    private final OrderRepository orderRepository;
    private final BookingRepository bookingRepository;

    public DashboardStatsDTO getDashboardStats() {
        long totalUsers = userRepository.count();
        Long totalPhotos = orderItemRepository.sumTotalQuantity();
        if (totalPhotos == null) {
            totalPhotos = 0L;
        }
        long totalPendingOrders = orderRepository.countByStatusIn(
                Arrays.asList(OrderStatus.PENDING, OrderStatus.PENDING_PAYMENT));

        YearMonth currentMonth = YearMonth.now();
        LocalDateTime startOfMonth = currentMonth.atDay(1).atStartOfDay();
        LocalDateTime endOfMonth = currentMonth.atEndOfMonth().atTime(23, 59, 59);

        List<OrderStatus> revenueStatuses = OrderTotals.confirmedPaidStatuses();
        BigDecimal totalRevenue = orderRepository.sumTotalAmountByStatusInAndCreatedAtBetween(
                revenueStatuses, startOfMonth, endOfMonth);

        if (totalRevenue == null) {
            totalRevenue = BigDecimal.ZERO;
        }

        // Average Order Value
        BigDecimal totalLifetimeRevenue = orderRepository.sumTotalRevenue(revenueStatuses);
        long completedOrdersCount = orderRepository.countCompletedOrders(revenueStatuses);
        BigDecimal averageOrderValue = BigDecimal.ZERO;
        if (completedOrdersCount > 0 && totalLifetimeRevenue != null) {
            averageOrderValue = totalLifetimeRevenue.divide(BigDecimal.valueOf(completedOrdersCount), 2, java.math.RoundingMode.HALF_UP);
        }

        return DashboardStatsDTO.builder()
                .totalUsers(totalUsers)
                .totalPhotos(totalPhotos)
                .totalPendingOrders(totalPendingOrders)
                .totalRevenue(totalRevenue)
                .averageOrderValue(averageOrderValue)
                .build();
    }

    public List<com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO> getTopClientsByRevenue() {
        List<OrderStatus> revenueStatuses = OrderTotals.confirmedPaidStatuses();
        return orderRepository.findTopClientsByRevenue(revenueStatuses, org.springframework.data.domain.PageRequest.of(0, 5));
    }

    public com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO getYearlyRevenueChart() {
        List<String> labels = new java.util.ArrayList<>();
        List<BigDecimal> data = new java.util.ArrayList<>();
        List<OrderStatus> revenueStatuses = OrderTotals.confirmedPaidStatuses();

        YearMonth currentMonth = YearMonth.now();
        for (int i = 5; i >= 0; i--) {
            YearMonth month = currentMonth.minusMonths(i);
            labels.add(month.getMonth().name());
            
            LocalDateTime start = month.atDay(1).atStartOfDay();
            LocalDateTime end = month.atEndOfMonth().atTime(23, 59, 59);
            
            BigDecimal monthlyRev = orderRepository.sumTotalAmountByStatusInAndCreatedAtBetween(revenueStatuses, start, end);
            data.add(monthlyRev != null ? monthlyRev : BigDecimal.ZERO);
        }

        return com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO.builder()
                .labels(labels)
                .data(data)
                .build();
    }

    public com.studiophoto.photoappbackend.admin.dto.ChartDataDTO getChartData() {
        final int days = 30;
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        List<String> labels = java.util.stream.Stream.iterate(startDate, date -> date.plusDays(1))
                .limit(days)
                .map(LocalDate::toString)
                .collect(java.util.stream.Collectors.toList());

        List<Long> newUsers = new java.util.ArrayList<>();
        List<Long> uploadedPhotos = new java.util.ArrayList<>();

        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.atTime(23, 59, 59);

            long users = userRepository.countByCreatedAtBetween(startOfDay, endOfDay);
            newUsers.add(users);

            Long photos = orderItemRepository.sumQuantityByOrderCreatedAtBetween(startOfDay, endOfDay);
            uploadedPhotos.add(photos != null ? photos : 0L);
        }

        return com.studiophoto.photoappbackend.admin.dto.ChartDataDTO.builder()
                .labels(labels)
                .newUsers(newUsers)
                .uploadedPhotos(uploadedPhotos)
                .build();
    }

    public List<com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO> getRecentActivity() {
        List<com.studiophoto.photoappbackend.model.User> recentUsers = userRepository.findTop5ByOrderByCreatedAtDesc();
        List<com.studiophoto.photoappbackend.order.Order> recentOrders = orderRepository.findTop5ByOrderByCreatedAtDesc();

        List<com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO> activities = new java.util.ArrayList<>();

        recentUsers.stream()
                .filter(user -> user.getCreatedAt() != null)
                .forEach(user -> activities.add(
                com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO.builder()
                        .description("Nouvel utilisateur: " + user.getFirstname())
                        .timestamp(user.getCreatedAt())
                        .icon("fas fa-user-plus")
                        .color("var(--primary-color)")
                        .type("user")
                        .entityId(Long.valueOf(user.getId()))
                        .build()
        ));

        recentOrders.stream()
                .filter(order -> order.getCreatedAt() != null)
                .forEach(order -> activities.add(
                com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO.builder()
                        .description("Nouvelle commande #" + order.getId())
                        .timestamp(order.getCreatedAt())
                        .icon("fas fa-shopping-cart")
                        .color("var(--success-color)")
                        .type("order")
                        .entityId(order.getId())
                        .build()
        ));

        activities.sort(java.util.Comparator.comparing(com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO::getTimestamp).reversed());

        return activities.stream().limit(5).collect(java.util.stream.Collectors.toList());
    }

    public com.studiophoto.photoappbackend.admin.dto.OrderStatusChartDTO getOrderStatusChartData() {
        List<String> labels = new java.util.ArrayList<>();
        List<Long> data = new java.util.ArrayList<>();
        List<String> colors = new java.util.ArrayList<>();

        for (OrderStatus status : OrderStatus.values()) {
            labels.add(status.name());
            data.add(orderRepository.countByStatus(status));
            // Assign a color based on status
            switch (status) {
                case PENDING:
                    colors.add("#FFCE56"); // Warning yellow
                    break;
                case PROCESSING:
                    colors.add("#36A2EB"); // Info blue
                    break;
                case COMPLETED:
                    colors.add("#2ECC71"); // Success green
                    break;
                case CANCELLED:
                    colors.add("#FF6384"); // Danger red
                    break;
                case PENDING_PAYMENT:
                    colors.add("#95A5A6"); // Grey
                    break;
                default:
                    colors.add("#CCCCCC"); // Default light grey
                    break;
            }
        }

        return com.studiophoto.photoappbackend.admin.dto.OrderStatusChartDTO.builder()
                .labels(labels)
                .data(data)
                .backgroundColors(colors)
                .build();
    }

    public com.studiophoto.photoappbackend.admin.dto.BookingStatusChartDTO getBookingStatusChartData() {
        List<String> labels = new java.util.ArrayList<>();
        List<Long> data = new java.util.ArrayList<>();
        List<String> colors = new java.util.ArrayList<>();

        for (BookingStatus status : BookingStatus.values()) {
            labels.add(status.name());
            data.add(bookingRepository.countByStatus(status));
            // Assign a color based on status
            switch (status) {
                case PENDING:
                    colors.add("#FFCE56"); // Warning yellow
                    break;
                case CONFIRMED:
                    colors.add("#2ECC71"); // Success green
                    break;
                case CANCELLED:
                    colors.add("#FF6384"); // Danger red
                    break;
                default:
                    colors.add("#CCCCCC"); // Default light grey
                    break;
            }
        }

        return com.studiophoto.photoappbackend.admin.dto.BookingStatusChartDTO.builder()
                .labels(labels)
                .data(data)
                .backgroundColors(colors)
                .build();
    }

    public com.studiophoto.photoappbackend.admin.dto.BookingsPerDayChartDTO getBookingsPerDayChartData() {
        final int days = 30;
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusDays(days - 1);

        List<String> labels = java.util.stream.Stream.iterate(startDate, date -> date.plusDays(1))
                .limit(days)
                .map(LocalDate::toString)
                .collect(java.util.stream.Collectors.toList());

        List<Long> dailyBookings = new java.util.ArrayList<>();

        for (LocalDate date = startDate; !date.isAfter(endDate); date = date.plusDays(1)) {
            LocalDateTime startOfDay = date.atStartOfDay();
            LocalDateTime endOfDay = date.atTime(23, 59, 59);
            dailyBookings.add(bookingRepository.countByStartTimeBetween(startOfDay, endOfDay));
        }

        return com.studiophoto.photoappbackend.admin.dto.BookingsPerDayChartDTO.builder()
                .labels(labels)
                .data(dailyBookings)
                .build();
    }

    public com.studiophoto.photoappbackend.admin.dto.PhotoFormatChartDTO getPhotoFormatChartData() {
        List<Object[]> results = orderItemRepository.countByPhotoSize();
        List<String> labels = new java.util.ArrayList<>();
        List<Long> data = new java.util.ArrayList<>();
        List<String> colors = Arrays.asList("#FF6384", "#36A2EB", "#FFCE56", "#4BC0C0", "#9966FF", "#FF9F40");

        int colorIndex = 0;
        List<String> backgroundColors = new java.util.ArrayList<>();

        for (Object[] result : results) {
            labels.add(result[0] != null ? result[0].toString() : "—");
            data.add(toLong(result.length > 1 ? result[1] : null));
            backgroundColors.add(colors.get(colorIndex % colors.size()));
            colorIndex++;
        }

        return com.studiophoto.photoappbackend.admin.dto.PhotoFormatChartDTO.builder()
                .labels(labels)
                .data(data)
                .backgroundColors(backgroundColors)
                .build();
    }

    public com.studiophoto.photoappbackend.admin.dto.WeeklyActivityChartDTO getWeeklyActivityChartData() {
        List<String> labels = Arrays.asList("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche");
        Long[] activityData = new Long[7];
        Arrays.fill(activityData, 0L);

        List<com.studiophoto.photoappbackend.order.Order> allOrders = orderRepository.findAll();
        for (com.studiophoto.photoappbackend.order.Order order : allOrders) {
            if (order.getCreatedAt() == null) {
                continue;
            }
            int dayOfWeek = order.getCreatedAt().getDayOfWeek().getValue(); // 1 (Mon) to 7 (Sun)
            activityData[dayOfWeek - 1]++;
        }

        return com.studiophoto.photoappbackend.admin.dto.WeeklyActivityChartDTO.builder()
                .labels(labels)
                .data(Arrays.asList(activityData))
                .build();
    }

    private static long toLong(Object value) {
        if (value == null) {
            return 0L;
        }
        if (value instanceof Number number) {
            return number.longValue();
        }
        try {
            return Long.parseLong(value.toString());
        } catch (NumberFormatException e) {
            return 0L;
        }
    }
}

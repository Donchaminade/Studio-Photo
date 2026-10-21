package com.studiophoto.photoappbackend.admin;

import com.studiophoto.photoappbackend.admin.DashboardService;
import com.studiophoto.photoappbackend.admin.dto.DashboardStatsDTO;
import com.studiophoto.photoappbackend.admin.dto.OrderStatusChartDTO;
import com.studiophoto.photoappbackend.admin.dto.BookingStatusChartDTO;
import com.studiophoto.photoappbackend.admin.dto.BookingsPerDayChartDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin/api")
@RequiredArgsConstructor
public class AdminDashboardApiController {

    private final DashboardService dashboardService;

    @GetMapping("/dashboard-stats")
    public ResponseEntity<DashboardStatsDTO> getDashboardStats() {
        DashboardStatsDTO stats = dashboardService.getDashboardStats();
        return ResponseEntity.ok(stats);
    }

    @GetMapping("/chart-data")
    public ResponseEntity<com.studiophoto.photoappbackend.admin.dto.ChartDataDTO> getChartData() {
        return ResponseEntity.ok(dashboardService.getChartData());
    }

    @GetMapping("/recent-activity")
    public ResponseEntity<java.util.List<com.studiophoto.photoappbackend.admin.dto.ActivityItemDTO>> getRecentActivity() {
        return ResponseEntity.ok(dashboardService.getRecentActivity());
    }

    @GetMapping("/chart/order-status")
    public ResponseEntity<OrderStatusChartDTO> getOrderStatusChart() {
        return ResponseEntity.ok(dashboardService.getOrderStatusChartData());
    }

    @GetMapping("/chart/booking-status")
    public ResponseEntity<BookingStatusChartDTO> getBookingStatusChart() {
        return ResponseEntity.ok(dashboardService.getBookingStatusChartData());
    }

    @GetMapping("/chart/bookings-per-day")
    public ResponseEntity<BookingsPerDayChartDTO> getBookingsPerDayChart() {
        return ResponseEntity.ok(dashboardService.getBookingsPerDayChartData());
    }

    @GetMapping("/top-clients")
    public ResponseEntity<java.util.List<com.studiophoto.photoappbackend.admin.dto.ClientRevenueDTO>> getTopClients() {
        return ResponseEntity.ok(dashboardService.getTopClientsByRevenue());
    }

    @GetMapping("/chart/revenue")
    public ResponseEntity<com.studiophoto.photoappbackend.admin.dto.RevenueChartDTO> getRevenueChart() {
        return ResponseEntity.ok(dashboardService.getYearlyRevenueChart());
    }

    @GetMapping("/chart/photo-formats")
    public ResponseEntity<com.studiophoto.photoappbackend.admin.dto.PhotoFormatChartDTO> getPhotoFormatChart() {
        return ResponseEntity.ok(dashboardService.getPhotoFormatChartData());
    }

    @GetMapping("/chart/weekly-activity")
    public ResponseEntity<com.studiophoto.photoappbackend.admin.dto.WeeklyActivityChartDTO> getWeeklyActivityChart() {
        return ResponseEntity.ok(dashboardService.getWeeklyActivityChartData());
    }
}

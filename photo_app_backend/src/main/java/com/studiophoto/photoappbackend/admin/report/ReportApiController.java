package com.studiophoto.photoappbackend.admin.report;

import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.Collections;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin/api/reports")
@RequiredArgsConstructor
public class ReportApiController {

    private final ReportService reportService;

    @GetMapping("/summary")
    public ResponseEntity<Map<String, Object>> getReportSummary(
            @RequestParam(name = "startDate", required = false) String startDateStr,
            @RequestParam(name = "endDate", required = false) String endDateStr) {

        LocalDateTime startDate = parseDate(startDateStr, LocalDate.now().minusMonths(1));
        LocalDateTime endDate = parseDate(endDateStr, LocalDate.now());

        ReportDTO reportData = reportService.generateReport(startDate, endDate);

        Map<String, Object> summary = Map.of(
                "totalNewUsers", reportData.getTotalNewUsers(),
                "totalOrders", reportData.getTotalOrders(),
                "totalBookings", reportData.getTotalBookings(),
                "totalRevenue", reportData.getTotalRevenue()
        );
        return ResponseEntity.ok(summary);
    }

    @GetMapping("/recent-orders")
    public ResponseEntity<List<com.studiophoto.photoappbackend.order.Order>> getRecentOrders(
            @RequestParam(name = "startDate", required = false) String startDateStr,
            @RequestParam(name = "endDate", required = false) String endDateStr) {

        LocalDateTime startDate = parseDate(startDateStr, LocalDate.now().minusMonths(1));
        LocalDateTime endDate = parseDate(endDateStr, LocalDate.now());

        ReportDTO reportData = reportService.generateReport(startDate, endDate); // Generates all data, but we only need orders here
        return ResponseEntity.ok(reportData.getRecentOrders());
    }

    @GetMapping("/recent-users")
    public ResponseEntity<List<com.studiophoto.photoappbackend.model.User>> getRecentUsers(
            @RequestParam(name = "startDate", required = false) String startDateStr,
            @RequestParam(name = "endDate", required = false) String endDateStr) {

        LocalDateTime startDate = parseDate(startDateStr, LocalDate.now().minusMonths(1));
        LocalDateTime endDate = parseDate(endDateStr, LocalDate.now());

        ReportDTO reportData = reportService.generateReport(startDate, endDate); // Generates all data, but we only need users here
        return ResponseEntity.ok(reportData.getRecentUsers());
    }

    private LocalDateTime parseDate(String dateStr, LocalDate defaultValue) {
        if (dateStr != null && !dateStr.isEmpty()) {
            try {
                return LocalDate.parse(dateStr).atStartOfDay();
            } catch (DateTimeParseException e) {
                // Log parsing error
            }
        }
        return defaultValue.atStartOfDay();
    }
}

package com.studiophoto.photoappbackend.admin.report;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.thymeleaf.context.Context;

import java.io.IOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Controller
@RequestMapping("/admin/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;
    private final PdfGenerationService pdfGenerationService;

    @GetMapping
    public String showReportsPage(Model model) {
        // Default date range for display
        LocalDate endDate = LocalDate.now();
        LocalDate startDate = endDate.minusMonths(1); // Last month

        model.addAttribute("startDate", startDate);
        model.addAttribute("endDate", endDate);
        return "admin/reports/report";
    }

    @GetMapping("/download-pdf")
    public ResponseEntity<byte[]> downloadPdfReport(
            @RequestParam(name = "startDate", required = false) String startDateStr,
            @RequestParam(name = "endDate", required = false) String endDateStr) throws IOException {

        LocalDateTime startDate = parseDate(startDateStr, LocalDate.now().minusMonths(1));
        LocalDateTime endDate = parseDate(endDateStr, LocalDate.now());

        ReportDTO reportData = reportService.generateReport(startDate, endDate);

        // Prepare Thymeleaf context for PDF template
        Context context = new Context();
        context.setVariable("report", reportData);
        context.setVariable("startDate", startDate.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
        context.setVariable("endDate", endDate.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy")));
        context.setVariable("generatedDate", LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));


        byte[] pdfBytes = pdfGenerationService.generatePdfFromHtml("admin/reports/report-pdf", context);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_PDF);
        String filename = "report_" + startDate.toLocalDate() + "_" + endDate.toLocalDate() + ".pdf";
        headers.setContentDispositionFormData("attachment", filename);
        headers.setContentLength(pdfBytes.length);

        return new ResponseEntity<>(pdfBytes, headers, org.springframework.http.HttpStatus.OK);
    }

    private LocalDateTime parseDate(String dateStr, LocalDate defaultValue) {
        if (dateStr != null && !dateStr.isEmpty()) {
            try {
                return LocalDate.parse(dateStr).atStartOfDay();
            } catch (Exception e) {
                // Log parsing error
            }
        }
        return defaultValue.atStartOfDay();
    }
}

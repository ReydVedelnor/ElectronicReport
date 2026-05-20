package com.student.backend.report.htmlpdf.api;

import com.student.backend.report.htmlpdf.application.GenerateDailyReportPdfUseCase;
import com.student.backend.report.htmlpdf.dto.GeneratedPdfReport;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/reports/daily")
public class DailyReportPdfController {

    private final GenerateDailyReportPdfUseCase generateDailyReportPdfUseCase;

    @GetMapping("/pdf")
    public ResponseEntity<byte[]> generateDailyReportPdf(
            @RequestParam UUID departmentId,
            @RequestParam String date
    ) {
        GeneratedPdfReport report = generateDailyReportPdfUseCase.generate(departmentId, date);

        ContentDisposition contentDisposition = ContentDisposition.inline()
                .filename(report.getFilename())
                .build();

        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, contentDisposition.toString())
                .body(report.getContent());
    }
}
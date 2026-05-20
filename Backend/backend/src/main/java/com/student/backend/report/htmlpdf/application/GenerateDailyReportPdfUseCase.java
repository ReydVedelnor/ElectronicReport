package com.student.backend.report.htmlpdf.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.report.htmlpdf.dto.DailyReportPdfData;
import com.student.backend.report.htmlpdf.dto.GeneratedPdfReport;
import com.student.backend.report.htmlpdf.service.DailyReportHtmlRenderer;
import com.student.backend.report.htmlpdf.service.DailyReportPdfDataBuilder;
import com.student.backend.report.htmlpdf.service.HtmlToPdfService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.format.ResolverStyle;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GenerateDailyReportPdfUseCase {

    private static final DateTimeFormatter REQUEST_DATE_FORMATTER =
            DateTimeFormatter.ofPattern("dd-MM-uuuu").withResolverStyle(ResolverStyle.STRICT);

    private static final DateTimeFormatter FILE_DATE_FORMATTER =
            DateTimeFormatter.ISO_LOCAL_DATE;

    private final DailyReportPdfDataBuilder dailyReportPdfDataBuilder;
    private final DailyReportHtmlRenderer dailyReportHtmlRenderer;
    private final HtmlToPdfService htmlToPdfService;

    public GeneratedPdfReport generate(UUID departmentId, String date) {
        if (departmentId == null) {
            throw new BadRequestException("departmentId обязателен");
        }

        LocalDate reportDate = parseDate(date);

        DailyReportPdfData data = dailyReportPdfDataBuilder.build(departmentId, reportDate);
        String html = dailyReportHtmlRenderer.render(data);
        byte[] pdf = htmlToPdfService.convert(html);

        String filename = "daily-report-" + reportDate.format(FILE_DATE_FORMATTER) + ".pdf";

        return new GeneratedPdfReport(filename, pdf);
    }

    private LocalDate parseDate(String date) {
        if (date == null || date.trim().isEmpty()) {
            throw new BadRequestException("date обязателен");
        }

        try {
            return LocalDate.parse(date.trim(), REQUEST_DATE_FORMATTER);
        } catch (DateTimeParseException ex) {
            throw new BadRequestException("date должен быть в формате dd-MM-yyyy");
        }
    }
}
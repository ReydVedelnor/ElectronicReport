package com.student.backend.report.api;

import com.student.backend.report.application.GetShiftReportFormUseCase;
import com.student.backend.report.application.SaveReportValuesUseCase;
import com.student.backend.report.dto.request.SaveReportValuesRequest;
import com.student.backend.report.dto.response.SaveReportValuesResponse;
import com.student.backend.report.dto.response.ShiftReportFormResponse;

import com.student.backend.report.application.GetReportPeriodTableUseCase;
import com.student.backend.report.dto.response.ReportPeriodTableResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class ReportController {

    private final GetShiftReportFormUseCase getShiftReportFormUseCase;
    private final SaveReportValuesUseCase saveReportValuesUseCase;

    @GetMapping("/api/shifts/{shiftId}/report-form")
    public ShiftReportFormResponse getShiftReportForm(@PathVariable UUID shiftId) {
        return getShiftReportFormUseCase.getByShiftId(shiftId);
    }

    @PutMapping("/api/reports/{reportId}/values")
    public SaveReportValuesResponse saveReportValues(
            @PathVariable UUID reportId,
            @RequestBody SaveReportValuesRequest request
    ) {
        return saveReportValuesUseCase.save(reportId, request);
    }


    // Получение множества репортов для таблицы за период
    private final GetReportPeriodTableUseCase getReportPeriodTableUseCase;

    @GetMapping("/api/reports/period")
    public ReportPeriodTableResponse getPeriodTable(
            @RequestParam UUID departmentId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateFrom,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate dateTo
    ) {
        return getReportPeriodTableUseCase.execute(departmentId, dateFrom, dateTo);
    }
}
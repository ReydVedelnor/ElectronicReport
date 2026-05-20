package com.student.backend.report.dto.response;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Value
@Builder
public class ReportPeriodTableResponse {
    UUID departmentId;
    String departmentName;
    Period period;
    List<ReportPeriodColumnResponse> columns;
    List<ReportPeriodRowResponse> rows;

    @Value
    @Builder
    public static class Period {
        LocalDate dateFrom;
        LocalDate dateTo;
    }
}
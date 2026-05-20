package com.student.backend.report.dto.response;

import lombok.Builder;
import lombok.Value;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Value
@Builder
public class ReportPeriodColumnResponse {
    String columnKey;
    LocalDate date;

    UUID scheduleId;
    String scheduleName;
    String shiftLabel;
    String timeLabel;

    String columnStatus; // HAS_SHIFT / MISSING_SHIFT

    OffsetDateTime startedAt;
    OffsetDateTime endedAt;

    UUID shiftId;
    UUID reportId;
}
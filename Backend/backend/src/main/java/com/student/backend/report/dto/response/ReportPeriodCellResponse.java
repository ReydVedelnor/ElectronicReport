package com.student.backend.report.dto.response;

import lombok.Builder;
import lombok.Value;

import java.time.OffsetDateTime;
import java.util.UUID;

@Value
@Builder
public class ReportPeriodCellResponse {
    UUID attributeValueId;
    String value;
    OffsetDateTime changedAt;
    UUID reportId;
    UUID shiftId;
}
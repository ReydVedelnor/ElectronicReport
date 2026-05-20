package com.student.backend.report.dto.response;

import lombok.Builder;
import lombok.Value;

import java.util.Map;
import java.util.UUID;

@Value
@Builder
public class ReportPeriodRowResponse {
    String rowKey;
    UUID attributeId;
    String name;
    String nodeType;
    Integer sortOrder;

    Boolean isNumbered;
    String displayStyle;
    String dataType;
    String unit;

    Map<String, ReportPeriodCellResponse> values;
}
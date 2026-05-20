package com.student.backend.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ReportFormItemResponse {

    private UUID attributeId;
    private String name;
    private String nodeType;
    private Integer sortOrder;
    private Boolean isRequired;
    private Boolean isNumbered;
    private String displayStyle;
    private String dataType;
    private String unit;
    private String value;
}
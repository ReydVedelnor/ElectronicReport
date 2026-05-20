package com.student.backend.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class SavedReportValueResponse {

    private UUID attributeId;
    private UUID attributeValueId;
    private String value;
}
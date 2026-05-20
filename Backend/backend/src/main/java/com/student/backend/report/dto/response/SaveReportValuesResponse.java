package com.student.backend.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class SaveReportValuesResponse {

    private UUID reportId;
    private int savedCount;
    private List<SavedReportValueResponse> savedValues;
}
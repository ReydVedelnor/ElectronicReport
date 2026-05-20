package com.student.backend.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ShiftReportFormResponse {

    private UUID shiftId;
    private UUID reportId;
    private UUID templateId;
    private String templateName;
    private String reportStatus;
    private List<ReportFormGroupResponse> groups;
}
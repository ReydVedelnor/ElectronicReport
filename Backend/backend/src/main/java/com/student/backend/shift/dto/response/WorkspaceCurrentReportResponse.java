package com.student.backend.shift.dto.response;

import lombok.Builder;
import lombok.Value;

import java.util.UUID;

@Value
@Builder
public class WorkspaceCurrentReportResponse {
    UUID reportId;
    String status;
}
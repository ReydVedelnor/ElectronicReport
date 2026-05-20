package com.student.backend.shift.dto.response;

import lombok.Builder;
import lombok.Value;

import java.time.OffsetDateTime;
import java.util.UUID;

@Value
@Builder
public class WorkspaceCurrentShiftResponse {
    UUID shiftId;

    UUID departmentId;
    String departmentName;

    UUID scheduleId;
    String scheduleName;

    OffsetDateTime startedAt;
    OffsetDateTime plannedEndAt;
    String status;
}
package com.student.backend.shift.dto.response;

import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class WorkspaceCurrentResponse {
    String workspaceStatus; // NO_ACTIVE_SHIFT | ACTIVE_SHIFT | AUTO_CLOSED_SHIFT
    Boolean autoClosed;
    String autoCloseReason; // null | SCHEDULE_END_REACHED | MAX_DURATION_REACHED
    String message;

    WorkspaceCurrentShiftResponse shift;
    WorkspaceCurrentReportResponse report;
}
package com.student.backend.shift.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class OpenShiftResponse {

    private UUID shiftId;
    private UUID reportId;
    private UUID templateId;
    private String templateName;
    private String shiftStatus;
    private String reportStatus;
    private OffsetDateTime startedAt;
    private UUID departmentId;
    private UUID scheduleId;
    private UUID engineerUserId;

    // Блок данных о предыдущей смене
    private boolean previousShiftFound;
    private UUID previousShiftId;
    private String previousShiftStatus;
    private String previousShiftMessage;


}
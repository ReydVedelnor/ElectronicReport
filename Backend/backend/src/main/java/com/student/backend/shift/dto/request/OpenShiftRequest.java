package com.student.backend.shift.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.OffsetDateTime;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class OpenShiftRequest {

    private UUID departmentId;
    private UUID scheduleId;
    private UUID engineerUserId;
    private OffsetDateTime startedAt;
}
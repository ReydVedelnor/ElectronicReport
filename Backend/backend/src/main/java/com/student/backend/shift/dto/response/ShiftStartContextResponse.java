package com.student.backend.shift.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ShiftStartContextResponse {

    private UUID engineerUserId;
    private UUID departmentId;
    private String departmentName;
    private List<ShiftStartScheduleItemResponse> schedules;
}
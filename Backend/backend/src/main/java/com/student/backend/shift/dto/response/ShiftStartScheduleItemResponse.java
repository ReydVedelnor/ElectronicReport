package com.student.backend.shift.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalTime;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ShiftStartScheduleItemResponse {

    private UUID scheduleId;
    private String name;
    private Integer sortOrder;
    private LocalTime startTime;
    private LocalTime endTime;
    private Boolean crossesMidnight;
}
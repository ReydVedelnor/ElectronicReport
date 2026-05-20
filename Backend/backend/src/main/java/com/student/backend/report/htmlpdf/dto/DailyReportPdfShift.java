package com.student.backend.report.htmlpdf.dto;

import java.time.OffsetDateTime;
import java.util.UUID;

public class DailyReportPdfShift {

    private final UUID shiftId;
    private final String title;
    private final String time;
    private final boolean plannedOnly;
    private final OffsetDateTime accumulationEndTime;

    public DailyReportPdfShift(
            UUID shiftId,
            String title,
            String time,
            boolean plannedOnly,
            OffsetDateTime accumulationEndTime
    ) {
        this.shiftId = shiftId;
        this.title = title;
        this.time = time;
        this.plannedOnly = plannedOnly;
        this.accumulationEndTime = accumulationEndTime;
    }

    public UUID getShiftId() {
        return shiftId;
    }

    public String getTitle() {
        return title;
    }

    public String getTime() {
        return time;
    }

    public boolean isPlannedOnly() {
        return plannedOnly;
    }

    public OffsetDateTime getAccumulationEndTime() {
        return accumulationEndTime;
    }
}
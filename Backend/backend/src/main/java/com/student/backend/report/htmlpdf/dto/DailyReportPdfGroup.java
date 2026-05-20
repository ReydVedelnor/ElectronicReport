package com.student.backend.report.htmlpdf.dto;

import java.util.List;
import java.util.UUID;

public class DailyReportPdfGroup {

    private final UUID groupId;
    private final String name;
    private final Integer sortOrder;
    private final List<DailyReportPdfRow> rows;

    public DailyReportPdfGroup(UUID groupId, String name, Integer sortOrder, List<DailyReportPdfRow> rows) {
        this.groupId = groupId;
        this.name = name;
        this.sortOrder = sortOrder;
        this.rows = rows;
    }

    public UUID getGroupId() {
        return groupId;
    }

    public String getName() {
        return name;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public List<DailyReportPdfRow> getRows() {
        return rows;
    }
}
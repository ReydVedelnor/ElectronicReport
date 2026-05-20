package com.student.backend.report.htmlpdf.dto;

import java.util.List;
import java.util.UUID;

public class DailyReportPdfData {

    private final UUID departmentId;
    private final String departmentName;
    private final UUID templateId;
    private final String templateName;
    private final String reportDateText;
    private final String generatedDateText;
    private final List<DailyReportPdfShift> shifts;
    private final List<DailyReportPdfGroup> groups;
    private final List<String> notes;

    public DailyReportPdfData(
            UUID departmentId,
            String departmentName,
            UUID templateId,
            String templateName,
            String reportDateText,
            String generatedDateText,
            List<DailyReportPdfShift> shifts,
            List<DailyReportPdfGroup> groups,
            List<String> notes
    ) {
        this.departmentId = departmentId;
        this.departmentName = departmentName;
        this.templateId = templateId;
        this.templateName = templateName;
        this.reportDateText = reportDateText;
        this.generatedDateText = generatedDateText;
        this.shifts = shifts;
        this.groups = groups;
        this.notes = notes;
    }

    public UUID getDepartmentId() {
        return departmentId;
    }

    public String getDepartmentName() {
        return departmentName;
    }

    public UUID getTemplateId() {
        return templateId;
    }

    public String getTemplateName() {
        return templateName;
    }

    public String getReportDateText() {
        return reportDateText;
    }

    public String getGeneratedDateText() {
        return generatedDateText;
    }

    public List<DailyReportPdfShift> getShifts() {
        return shifts;
    }

    public List<DailyReportPdfGroup> getGroups() {
        return groups;
    }

    public List<String> getNotes() {
        return notes;
    }
}
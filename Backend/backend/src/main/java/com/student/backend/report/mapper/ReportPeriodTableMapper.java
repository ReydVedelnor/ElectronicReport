package com.student.backend.report.mapper;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.dto.response.ReportPeriodCellResponse;
import com.student.backend.report.dto.response.ReportPeriodColumnResponse;
import com.student.backend.report.dto.response.ReportPeriodRowResponse;
import com.student.backend.report.dto.response.ReportPeriodTableResponse;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.template.domain.model.Attribute;
import com.student.backend.template.domain.model.TemplateAttribute;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Component
@RequiredArgsConstructor
public class ReportPeriodTableMapper {

    private static final ZoneOffset PROJECT_OFFSET = ZoneOffset.of("+05:00");
    private static final DateTimeFormatter TIME_FORMATTER = DateTimeFormatter.ofPattern("HH:mm");

    public ReportPeriodTableResponse toResponse(
            Department department,
            LocalDate dateFrom,
            LocalDate dateTo,
            List<DepartmentSchedule> schedules,
            List<Shift> shifts,
            Map<UUID, ReportInstance> reportByShiftId,
            List<TemplateAttribute> templateAttributes,
            Map<String, AttributeValue> attributeValueIndex
    ) {
        List<ReportPeriodColumnResponse> columns = buildColumns(dateFrom, dateTo, schedules, shifts, reportByShiftId);
        List<ReportPeriodRowResponse> rows = buildRows(columns, templateAttributes, attributeValueIndex);

        return ReportPeriodTableResponse.builder()
                .departmentId(department.getDepartmentId())
                .departmentName(department.getName())
                .period(ReportPeriodTableResponse.Period.builder()
                        .dateFrom(dateFrom)
                        .dateTo(dateTo)
                        .build())
                .columns(columns)
                .rows(rows)
                .build();
    }

    private List<ReportPeriodColumnResponse> buildColumns(
            LocalDate dateFrom,
            LocalDate dateTo,
            List<DepartmentSchedule> schedules,
            List<Shift> shifts,
            Map<UUID, ReportInstance> reportByShiftId
    ) {
        Map<String, Shift> shiftIndex = indexShifts(shifts);

        List<ReportPeriodColumnResponse> result = new ArrayList<>();
        LocalDate current = dateFrom;

        while (!current.isAfter(dateTo)) {
            for (DepartmentSchedule schedule : schedules) {
                String shiftKey = buildShiftKey(current, schedule.getScheduleId());
                Shift shift = shiftIndex.get(shiftKey);
                ReportInstance reportInstance = shift == null ? null : reportByShiftId.get(shift.getShiftId());

                result.add(ReportPeriodColumnResponse.builder()
                        .columnKey(buildColumnKey(current, schedule.getSortOrder()))
                        .date(current)
                        .scheduleId(schedule.getScheduleId())
                        .scheduleName(schedule.getName())
                        .shiftLabel(schedule.getName())
                        .timeLabel(formatTimeLabel(schedule.getStartTime(), schedule.getEndTime()))
                        .columnStatus(shift == null ? "MISSING_SHIFT" : "HAS_SHIFT")
                        .startedAt(shift == null ? null : shift.getStartedAt())
                        .endedAt(shift == null ? null : shift.getEndedAt())
                        .shiftId(shift == null ? null : shift.getShiftId())
                        .reportId(reportInstance == null ? null : reportInstance.getReportId())
                        .build());
            }
            current = current.plusDays(1);
        }

        return result;
    }

    private Map<String, Shift> indexShifts(List<Shift> shifts) {
        Map<String, Shift> result = new HashMap<>();

        for (Shift shift : shifts) {
            LocalDate businessDate = shift.getStartedAt()
                    .atZoneSameInstant(PROJECT_OFFSET)
                    .toLocalDate();

            String key = buildShiftKey(businessDate, shift.getSchedule().getScheduleId());

            if (result.containsKey(key)) {
                throw new BadRequestException("Найдено несколько смен для одной даты и schedule");
            }

            result.put(key, shift);
        }

        return result;
    }

    private List<ReportPeriodRowResponse> buildRows(
            List<ReportPeriodColumnResponse> columns,
            List<TemplateAttribute> templateAttributes,
            Map<String, AttributeValue> attributeValueIndex
    ) {
        List<ReportPeriodRowResponse> rows = new ArrayList<>();

        for (TemplateAttribute templateAttribute : templateAttributes) {
            Attribute attribute = templateAttribute.getAttribute();

            Map<String, ReportPeriodCellResponse> values = new LinkedHashMap<>();

            for (ReportPeriodColumnResponse column : columns) {
                if (column.getReportId() == null) {
                    values.put(column.getColumnKey(), null);
                    continue;
                }

                String valueKey = buildValueKey(
                        templateAttribute.getAttributeId(),
                        column.getReportId()
                );

                AttributeValue attributeValue = attributeValueIndex.get(valueKey);

                if (attributeValue == null) {
                    values.put(column.getColumnKey(), null);
                    continue;
                }

                values.put(
                        column.getColumnKey(),
                        ReportPeriodCellResponse.builder()
                                .attributeValueId(attributeValue.getAttributeValueId())
                                .value(attributeValue.getValueText())
                                .changedAt(attributeValue.getUpdatedAt())
                                .reportId(attributeValue.getReport().getReportId())
                                .shiftId(column.getShiftId())
                                .build()
                );
            }

            rows.add(ReportPeriodRowResponse.builder()
                    .rowKey("attribute_" + attribute.getAttributeId())
                    .attributeId(attribute.getAttributeId())
                    .name(attribute.getName())
                    .nodeType(attribute.getNodeType() == null ? null : attribute.getNodeType().name().toLowerCase())
                    .sortOrder(templateAttribute.getSortOrder())
                    .isNumbered(templateAttribute.getIsNumbered())
                    .displayStyle(templateAttribute.getDisplayStyle() == null
                            ? null
                            : templateAttribute.getDisplayStyle().name().toLowerCase())
                    .dataType(attribute.getDataType() == null
                            ? null
                            : attribute.getDataType().getName().toLowerCase())
                    .unit(attribute.getUnit() == null
                            ? null
                            : attribute.getUnit().getShortName())
                    .values(values)
                    .build());
        }

        return rows;
    }

    private String buildColumnKey(LocalDate date, Integer sortOrder) {
        return date + "_" + sortOrder;
    }

    private String buildShiftKey(LocalDate date, UUID scheduleId) {
        return date + "::" + scheduleId;
    }

    private String buildValueKey(UUID attributeId, UUID reportId) {
        return attributeId + "::" + reportId;
    }

    private String formatTimeLabel(LocalTime startTime, LocalTime endTime) {
        return TIME_FORMATTER.format(startTime) + "-" + TIME_FORMATTER.format(endTime);
    }
}
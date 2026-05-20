package com.student.backend.report.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.organization.domain.model.DepartmentTemplate;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentScheduleRepository;
import com.student.backend.organization.domain.repository.DepartmentTemplateRepository;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.AttributeValueRepository;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.report.dto.response.ReportPeriodTableResponse;
import com.student.backend.report.mapper.ReportPeriodTableMapper;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.shift.domain.repository.ShiftRepository;
import com.student.backend.template.domain.model.TemplateAttribute;
import com.student.backend.template.domain.repository.TemplateAttributeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GetReportPeriodTableUseCase {

    private static final ZoneOffset PROJECT_OFFSET = ZoneOffset.of("+05:00");

    private final DepartmentRepository departmentRepository;
    private final DepartmentScheduleRepository departmentScheduleRepository;
    private final DepartmentTemplateRepository departmentTemplateRepository;

    private final ShiftRepository shiftRepository;
    private final ReportInstanceRepository reportInstanceRepository;
    private final AttributeValueRepository attributeValueRepository;
    private final TemplateAttributeRepository templateAttributeRepository;

    private final ReportPeriodTableMapper reportPeriodTableMapper;

    public ReportPeriodTableResponse execute(UUID departmentId, LocalDate dateFrom, LocalDate dateTo) {
        validate(departmentId, dateFrom, dateTo);

        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new NotFoundException("Подразделение не найдено"));

        List<DepartmentSchedule> schedules = departmentScheduleRepository
                .findAllByDepartment_DepartmentIdOrderBySortOrderAsc(departmentId);

        if (schedules.isEmpty()) {
            throw new NotFoundException("Для подразделения не найдены расписания смен");
        }

        DepartmentTemplate departmentTemplate = departmentTemplateRepository
                .findFirstByDepartmentId(departmentId)
                .orElseThrow(() -> new NotFoundException("Для подразделения не найден шаблон"));

        UUID templateId = departmentTemplate.getTemplateId();

        OffsetDateTime fromInclusive = dateFrom.atStartOfDay().atOffset(PROJECT_OFFSET);
        OffsetDateTime toExclusive = dateTo.plusDays(1).atStartOfDay().atOffset(PROJECT_OFFSET);

        List<Shift> shifts =
                shiftRepository.findAllByDepartment_DepartmentIdAndStartedAtGreaterThanEqualAndStartedAtLessThanOrderByStartedAtAsc(
                        departmentId,
                        fromInclusive,
                        toExclusive
                );

        Map<UUID, ReportInstance> reportByShiftId = loadReportByShiftId(shifts);

        validateTemplateConsistency(templateId, reportByShiftId.values());

        List<TemplateAttribute> templateAttributes =
                templateAttributeRepository.findAllByTemplateIdOrderBySortOrderAsc(templateId);

        List<AttributeValue> attributeValues = loadAttributeValues(reportByShiftId.values());
        Map<String, AttributeValue> attributeValueIndex = indexAttributeValues(attributeValues);

        return reportPeriodTableMapper.toResponse(
                department,
                dateFrom,
                dateTo,
                schedules,
                shifts,
                reportByShiftId,
                templateAttributes,
                attributeValueIndex
        );
    }

    private void validate(UUID departmentId, LocalDate dateFrom, LocalDate dateTo) {
        if (departmentId == null) {
            throw new BadRequestException("departmentId обязателен");
        }
        if (dateFrom == null) {
            throw new BadRequestException("dateFrom обязателен");
        }
        if (dateTo == null) {
            throw new BadRequestException("dateTo обязателен");
        }
        if (dateFrom.isAfter(dateTo)) {
            throw new BadRequestException("dateFrom не может быть позже dateTo");
        }
    }

    private Map<UUID, ReportInstance> loadReportByShiftId(List<Shift> shifts) {
        if (shifts.isEmpty()) {
            return Map.of();
        }

        List<UUID> shiftIds = shifts.stream()
                .map(Shift::getShiftId)
                .toList();

        List<ReportInstance> reportInstances = reportInstanceRepository.findAllByShift_ShiftIdIn(shiftIds);

        return reportInstances.stream()
                .collect(Collectors.toMap(
                        reportInstance -> reportInstance.getShift().getShiftId(),
                        Function.identity(),
                        (left, right) -> left
                ));
    }

    private void validateTemplateConsistency(UUID expectedTemplateId, Collection<ReportInstance> reportInstances) {
        for (ReportInstance reportInstance : reportInstances) {
            if (reportInstance.getTemplate() == null || reportInstance.getTemplate().getTemplateId() == null) {
                throw new BadRequestException("У reportInstance отсутствует templateId");
            }

            if (!expectedTemplateId.equals(reportInstance.getTemplate().getTemplateId())) {
                throw new BadRequestException(
                        "За выбранный период найдены смены с другим шаблоном. Таблица не может быть построена"
                );
            }
        }
    }

    private List<AttributeValue> loadAttributeValues(Collection<ReportInstance> reportInstances) {
        if (reportInstances.isEmpty()) {
            return List.of();
        }

        List<UUID> reportIds = reportInstances.stream()
                .map(ReportInstance::getReportId)
                .toList();

        return attributeValueRepository.findAllByReport_ReportIdIn(reportIds);
    }

    private Map<String, AttributeValue> indexAttributeValues(List<AttributeValue> attributeValues) {
        Map<String, AttributeValue> index = new HashMap<>();

        for (AttributeValue attributeValue : attributeValues) {
            index.put(
                    buildValueKey(
                            attributeValue.getAttribute().getAttributeId(),
                            attributeValue.getReport().getReportId()
                    ),
                    attributeValue
            );
        }

        return index;
    }

    private String buildValueKey(UUID attributeId, UUID reportId) {
        return attributeId + "::" + reportId;
    }
}
package com.student.backend.report.application;

import com.student.backend.common.exception.NotFoundException;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.AttributeValueRepository;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.report.dto.response.ReportFormGroupResponse;
import com.student.backend.report.dto.response.ReportFormItemResponse;
import com.student.backend.report.dto.response.ShiftReportFormResponse;
import com.student.backend.template.domain.model.AttributeGroup;
import com.student.backend.template.domain.model.TemplateAttribute;
import com.student.backend.template.domain.repository.AttributeGroupRepository;
import com.student.backend.template.domain.repository.TemplateAttributeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class GetShiftReportFormUseCase {

    private final ReportInstanceRepository reportInstanceRepository;
    private final TemplateAttributeRepository templateAttributeRepository;
    private final AttributeValueRepository attributeValueRepository;
    private final AttributeGroupRepository attributeGroupRepository;

    public ShiftReportFormResponse getByShiftId(UUID shiftId) {
        ReportInstance reportInstance = reportInstanceRepository.findByShift_ShiftId(shiftId)
                .orElseThrow(() -> new NotFoundException("Отчет по смене не найден"));

        List<TemplateAttribute> templateAttributes =
                templateAttributeRepository.findAllByTemplateIdOrderBySortOrderAsc(
                        reportInstance.getTemplate().getTemplateId()
                );

        Map<UUID, AttributeValue> currentValues = attributeValueRepository
                .findAllByReport_ReportId(reportInstance.getReportId())
                .stream()
                .collect(Collectors.toMap(
                        value -> value.getAttribute().getAttributeId(),
                        Function.identity()
                ));

        Map<UUID, AttributeGroup> groupsById = loadGroupsById(templateAttributes);

        List<ReportFormGroupResponse> groups = buildGroups(templateAttributes, currentValues, groupsById);

        return ShiftReportFormResponse.builder()
                .shiftId(reportInstance.getShift().getShiftId())
                .reportId(reportInstance.getReportId())
                .templateId(reportInstance.getTemplate().getTemplateId())
                .templateName(reportInstance.getTemplate().getName())
                .reportStatus(reportInstance.getStatus().name())
                .groups(groups)
                .build();
    }

    private Map<UUID, AttributeGroup> loadGroupsById(List<TemplateAttribute> templateAttributes) {
        List<UUID> groupIds = templateAttributes.stream()
                .map(templateAttribute -> templateAttribute.getAttribute().getGroupId())
                .distinct()
                .toList();

        List<AttributeGroup> groups = attributeGroupRepository.findAllById(groupIds);

        Map<UUID, AttributeGroup> groupsById = groups.stream()
                .collect(Collectors.toMap(
                        AttributeGroup::getGroupId,
                        Function.identity()
                ));

        for (UUID groupId : groupIds) {
            if (!groupsById.containsKey(groupId)) {
                throw new NotFoundException("Группа атрибутов не найдена: " + groupId);
            }
        }

        return groupsById;
    }

    private List<ReportFormGroupResponse> buildGroups(
            List<TemplateAttribute> templateAttributes,
            Map<UUID, AttributeValue> currentValues,
            Map<UUID, AttributeGroup> groupsById
    ) {
        Map<UUID, GroupAccumulator> groupedAttributes = new LinkedHashMap<>();

        for (TemplateAttribute templateAttribute : templateAttributes) {
            var attribute = templateAttribute.getAttribute();
            UUID groupId = attribute.getGroupId();

            AttributeGroup group = groupsById.get(groupId);

            if (group == null) {
                throw new NotFoundException("Группа атрибутов не найдена: " + groupId);
            }

            GroupAccumulator accumulator = groupedAttributes.computeIfAbsent(
                    groupId,
                    ignored -> new GroupAccumulator(group)
            );

            AttributeValue currentValue = currentValues.get(attribute.getAttributeId());

            ReportFormItemResponse item = ReportFormItemResponse.builder()
                    .attributeId(attribute.getAttributeId())
                    .name(attribute.getName())
                    .nodeType(attribute.getNodeType() == null ? null : attribute.getNodeType().name())
                    .sortOrder(templateAttribute.getSortOrder())
                    .isRequired(attribute.getIsRequired())
                    .isNumbered(templateAttribute.getIsNumbered())
                    .displayStyle(templateAttribute.getDisplayStyle() == null ? null : templateAttribute.getDisplayStyle().name())
                    .dataType(attribute.getDataType() == null ? null : attribute.getDataType().getBaseType())
                    .unit(attribute.getUnit() == null ? null : attribute.getUnit().getShortName())
                    .value(currentValue == null ? null : currentValue.getValueText())
                    .build();

            accumulator.addAttribute(item);
        }

        return groupedAttributes.values().stream()
                .map(GroupAccumulator::toResponse)
                .sorted(
                        Comparator
                                .comparing(ReportFormGroupResponse::getSortOrder, Comparator.nullsLast(Integer::compareTo))
                                .thenComparing(group -> normalizeForSort(group.getName()))
                                .thenComparing(group -> group.getGroupId().toString())
                )
                .toList();
    }

    private String normalizeForSort(String value) {
        if (value == null) {
            return "";
        }

        return value.trim().toLowerCase();
    }

    private static class GroupAccumulator {

        private final AttributeGroup group;
        private final List<ReportFormItemResponse> attributes = new ArrayList<>();
        private Integer sortOrder;

        private GroupAccumulator(AttributeGroup group) {
            this.group = group;
        }

        private void addAttribute(ReportFormItemResponse attribute) {
            attributes.add(attribute);

            if (attribute.getSortOrder() == null) {
                return;
            }

            if (sortOrder == null || attribute.getSortOrder() < sortOrder) {
                sortOrder = attribute.getSortOrder();
            }
        }

        private ReportFormGroupResponse toResponse() {
            List<ReportFormItemResponse> sortedAttributes = attributes.stream()
                    .sorted(
                            Comparator
                                    .comparing(ReportFormItemResponse::getSortOrder, Comparator.nullsLast(Integer::compareTo))
                                    .thenComparing(attribute -> attribute.getAttributeId().toString())
                    )
                    .toList();

            return ReportFormGroupResponse.builder()
                    .groupId(group.getGroupId())
                    .name(group.getName())
                    .description(group.getDescription())
                    .sortOrder(sortOrder)
                    .attributes(sortedAttributes)
                    .build();
        }
    }
}
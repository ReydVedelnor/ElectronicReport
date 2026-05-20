package com.student.backend.report.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class ReportFormGroupResponse {

    private UUID groupId;
    private String name;
    private String description;

    /**
     * Вычисляемое значение.
     * Берем минимальный sortOrder среди атрибутов этой группы.
     */
    private Integer sortOrder;

    private List<ReportFormItemResponse> attributes;
}
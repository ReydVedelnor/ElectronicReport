package com.student.backend.report.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class SaveReportValuesRequest {

    private UUID changedByUserId;
    private String comment;
    private List<SaveAttributeValueItemRequest> values;
}
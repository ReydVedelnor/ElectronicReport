package com.student.backend.employee.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class EmployeeDepartmentOptionResponse {

    private UUID departmentId;
    private UUID parentDepartmentId;
    private String name;
    private String shortName;
    private Integer hierarchyLevel;
    private Boolean isActive;
}
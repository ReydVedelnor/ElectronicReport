package com.student.backend.employee.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class EmployeeRoleOptionResponse {

    private UUID roleId;
    private String name;
    private String description;
    private Boolean isActive;
}
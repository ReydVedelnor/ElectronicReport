package com.student.backend.employee.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeListItemResponse {

    private UUID userId;
    private String fullName;
    private String login;

    private UUID roleId;
    private String roleName;
    private Boolean isRoleActive;

    private UUID departmentId;
    private String departmentName;
    private Boolean isDepartmentActive;

    private Boolean isActive;
}
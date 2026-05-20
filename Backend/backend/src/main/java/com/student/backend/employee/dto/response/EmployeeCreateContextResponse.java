package com.student.backend.employee.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
public class EmployeeCreateContextResponse {

    private UUID currentUserId;
    private UUID rootDepartmentId;
    private String rootDepartmentName;
    private List<EmployeeDepartmentOptionResponse> departments;
    private List<EmployeeRoleOptionResponse> roles;
}
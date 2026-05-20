package com.student.backend.employee.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeDetailsResponse {

    private EmployeeDetailsItemResponse employee;

    private List<EmployeeRoleOptionResponse> roles;

    private List<EmployeeDepartmentOptionResponse> departments;
}
package com.student.backend.employee.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmployeeDetailsItemResponse {

    private UUID userId;

    private String lastName;
    private String firstName;
    private String middleName;
    private String fullName;

    private String login;

    private UUID roleId;
    private String roleName;
    private Boolean roleIsActive;

    private UUID departmentId;
    private String departmentName;
    private Boolean departmentIsActive;

    private Boolean isActive;
}
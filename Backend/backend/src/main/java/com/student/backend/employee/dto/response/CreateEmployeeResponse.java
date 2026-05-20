package com.student.backend.employee.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class CreateEmployeeResponse {

    private UUID userId;
    private String fullName;
    private String login;
    private UUID roleId;
    private String roleName;
    private UUID departmentId;
    private String departmentName;
    private String generatedPassword;
    private Boolean isActive;
    private String message;
}
package com.student.backend.employee.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class UpdateEmployeeRequest {

    private UUID updatedByUserId;
    private String lastName;
    private String firstName;
    private String middleName;
    private UUID roleId;
    private UUID departmentId;
    private String login;
    private String password;
    private Boolean isActive;
}
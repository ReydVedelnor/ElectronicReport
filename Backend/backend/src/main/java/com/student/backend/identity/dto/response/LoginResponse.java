package com.student.backend.identity.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@AllArgsConstructor
public class LoginResponse {

    private UUID userId;
    private String login;
    private String fullName;
    private UUID roleId;
    private String roleName;
    private List<LoginModuleResponse> modules;
    private String message;
}
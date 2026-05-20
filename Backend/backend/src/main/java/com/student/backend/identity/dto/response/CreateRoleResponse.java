package com.student.backend.identity.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateRoleResponse {

    private UUID roleId;
    private String name;
    private String description;
    private Boolean isActive;


    // При создании роли участников всегда 0
    private Long participantsCount;

    // Передавать только подключенные модули
    private List<RoleDetailsModuleResponse> modules;

    private String message;
}
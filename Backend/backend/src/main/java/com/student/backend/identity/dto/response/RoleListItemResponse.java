package com.student.backend.identity.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoleListItemResponse {

    private UUID roleId;
    private String name;
    private String description;
    private Boolean isActive;

    /**
     * Количество активных сотрудников, которым назначена эта роль.
     */
    private Long participantsCount;
}
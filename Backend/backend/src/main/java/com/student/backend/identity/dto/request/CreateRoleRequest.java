package com.student.backend.identity.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;
import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CreateRoleRequest {

    private String name;
    private String description;

    /**
     * Можно не передавать или передать пустой список.
     * Тогда роль создастся без модулей.
     */
    private List<UUID> moduleIds;
}
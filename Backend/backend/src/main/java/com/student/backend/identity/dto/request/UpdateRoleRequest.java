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
public class UpdateRoleRequest {

    /**
     * Если null или не передан — не меняем.
     * Если передан — trim
     */
    private String name;

    /**
     * Если null или не передан — не меняем.
     * Если "" или "   " — очищаем до null.
     * Если текст — trim и сохраняем.
     */
    private String description;

    /**
     * Если null или не передан — не меняем.
     * Если true/false — активируем/деактивируем роль.
     */
    private Boolean isActive;

    /**
     * Если null или не передан — модули не меняем.
     * Если [] — очищаем все модули роли.
     * Если список UUID — полностью заменяем модули роли.
     */
    private List<UUID> moduleIds;
}
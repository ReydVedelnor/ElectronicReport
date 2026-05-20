// Список модулей, прикрепленных к роли

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
public class RoleDetailsModuleResponse {

    private UUID moduleId;
    private String slug;
    private String displayName;
    private String description;

    /**
     * true  - модуль включен у роли
     * false - модуль доступен в системе, но у роли не включен
     */
    private Boolean isEnabled;
}
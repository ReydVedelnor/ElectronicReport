package com.student.backend.identity.dto.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class GetRoleListRequest {

    private Integer page;
    private Integer size;

    /**
     * Поиск по названию и описанию роли.
     * Поиск регистронезависимый и по части строки.
     */
    private String search;

    /**
     * true  - только активные
     * false - только неактивные
     * all   - все
     *
     * По умолчанию: true
     */
    private String activity;
}
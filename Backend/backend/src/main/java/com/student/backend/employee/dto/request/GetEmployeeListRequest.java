package com.student.backend.employee.dto.request;

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
public class GetEmployeeListRequest {

    private UUID userId;

    private Integer page;
    private Integer size;

    /**
     * Универсальный поиск по части значения.
     * Ищем по:
     * - lastName
     * - firstName
     * - middleName
     * - login
     * - role.name
     * - department.name
     * - department.shortName
     */
    private String search;

    /**
     * Множественный фильтр по ролям.
     * Передача в query params:
     * ?roleIds=id1&roleIds=id2
     */
    private List<UUID> roleIds;

    /**
     * Множественный фильтр по подразделениям.
     * Передача в query params:
     * ?departmentIds=id1&departmentIds=id2
     */
    private List<UUID> departmentIds;

    /**
     * true | false | all
     * По умолчанию: true
     */
    private String activity;
}
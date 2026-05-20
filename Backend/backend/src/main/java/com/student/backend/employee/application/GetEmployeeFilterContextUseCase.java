package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.employee.dto.response.EmployeeActivityOptionResponse;
import com.student.backend.employee.dto.response.EmployeeDepartmentOptionResponse;
import com.student.backend.employee.dto.response.EmployeeFilterContextResponse;
import com.student.backend.employee.dto.response.EmployeeFilterDefaultsResponse;
import com.student.backend.employee.dto.response.EmployeeRoleOptionResponse;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Deque;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetEmployeeFilterContextUseCase {

    private final RoleRepository roleRepository;
    private final DepartmentRepository departmentRepository;
    private final EmployeeAccessService employeeAccessService;

    @Transactional(readOnly = true)
    public EmployeeFilterContextResponse get(UUID userId) {
        if (userId == null) {
            throw new BadRequestException("userId обязателен");
        }

        Department rootDepartment = employeeAccessService.getSingleActiveDepartment(userId);

        List<EmployeeDepartmentOptionResponse> departments = collectAvailableDepartments(rootDepartment);
        List<EmployeeRoleOptionResponse> roles = collectAvailableRoles();
        List<EmployeeActivityOptionResponse> activityOptions = buildActivityOptions();

        return EmployeeFilterContextResponse.builder()
                .roles(roles)
                .departments(departments)
                .activityOptions(activityOptions)
                .defaults(EmployeeFilterDefaultsResponse.builder()
                        .activity("true")
                        .build())
                .build();
    }

    private List<EmployeeRoleOptionResponse> collectAvailableRoles() {
        List<Role> roles = roleRepository.findAllByIsActiveTrueOrderByNameAsc();

        return roles.stream()
                .map(role -> EmployeeRoleOptionResponse.builder()
                        .roleId(role.getRoleId())
                        .name(role.getName())
                        .description(role.getDescription())
                        .isActive(role.getIsActive())
                        .build())
                .toList();
    }

    private List<EmployeeDepartmentOptionResponse> collectAvailableDepartments(Department rootDepartment) {
        List<Department> departments = new ArrayList<>();
        Deque<Department> queue = new ArrayDeque<>();
        queue.add(rootDepartment);

        while (!queue.isEmpty()) {
            Department current = queue.poll();
            departments.add(current);

            List<Department> children = departmentRepository
                    .findAllByParentDepartment_DepartmentIdAndIsActiveTrueOrderByNameAsc(current.getDepartmentId());

            queue.addAll(children);
        }

        departments.sort(
                Comparator
                        .comparing(Department::getHierarchyLevel, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(department -> normalizeForSort(department.getName()))
        );

        return departments.stream()
                .map(department -> EmployeeDepartmentOptionResponse.builder()
                        .departmentId(department.getDepartmentId())
                        .parentDepartmentId(
                                department.getParentDepartment() != null
                                        ? department.getParentDepartment().getDepartmentId()
                                        : null
                        )
                        .name(department.getName())
                        .shortName(department.getShortName())
                        .hierarchyLevel(department.getHierarchyLevel())
                        .isActive(department.isActive())
                        .build())
                .toList();
    }

    private List<EmployeeActivityOptionResponse> buildActivityOptions() {
        return List.of(
                EmployeeActivityOptionResponse.builder()
                        .code("true")
                        .name("Активные")
                        .build(),
                EmployeeActivityOptionResponse.builder()
                        .code("false")
                        .name("Неактивные")
                        .build(),
                EmployeeActivityOptionResponse.builder()
                        .code("all")
                        .name("Все")
                        .build()
        );
    }

    private String normalizeForSort(String value) {
        if (value == null) {
            return "";
        }
        return value.trim().toLowerCase(Locale.ROOT);
    }
}
package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.employee.dto.response.EmployeeCreateContextResponse;
import com.student.backend.employee.dto.response.EmployeeDepartmentOptionResponse;
import com.student.backend.employee.dto.response.EmployeeRoleOptionResponse;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class GetEmployeeCreateContextUseCase {

    private final UserRepository userRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final DepartmentRepository departmentRepository;
    private final RoleRepository roleRepository;
    private final EmployeeAccessService employeeAccessService;

    public EmployeeCreateContextResponse get(UUID userId) {
        Department rootDepartment = employeeAccessService.getSingleActiveDepartment(userId);

        List<Department> availableDepartments = collectActiveDepartmentTree(rootDepartment);
        List<Role> availableRoles = roleRepository.findAllByIsActiveTrueOrderByNameAsc();

        return EmployeeCreateContextResponse.builder()
                .currentUserId(userId)
                .rootDepartmentId(rootDepartment.getDepartmentId())
                .rootDepartmentName(rootDepartment.getName())
                .departments(
                        availableDepartments.stream()
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
                                .toList()
                )
                .roles(
                        availableRoles.stream()
                                .map(role -> EmployeeRoleOptionResponse.builder()
                                        .roleId(role.getRoleId())
                                        .name(role.getName())
                                        .description(role.getDescription())
                                        .isActive(role.getIsActive())
                                        .build())
                                .toList()
                )
                .build();
    }

    private List<Department> collectActiveDepartmentTree(Department rootDepartment) {
        List<Department> result = new ArrayList<>();
        Deque<Department> queue = new ArrayDeque<>();
        queue.add(rootDepartment);

        while (!queue.isEmpty()) {
            Department current = queue.poll();
            result.add(current);

            List<Department> children = departmentRepository
                    .findAllByParentDepartment_DepartmentIdAndIsActiveTrueOrderByNameAsc(current.getDepartmentId());

            queue.addAll(children);
        }

        result.sort(Comparator
                .comparing((Department d) -> d.getHierarchyLevel() == null ? Integer.MAX_VALUE : d.getHierarchyLevel())
                .thenComparing(Department::getName, String.CASE_INSENSITIVE_ORDER));

        return result;
    }
}
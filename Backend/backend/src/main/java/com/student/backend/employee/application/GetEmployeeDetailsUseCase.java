package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.employee.dto.response.EmployeeDepartmentOptionResponse;
import com.student.backend.employee.dto.response.EmployeeDetailsItemResponse;
import com.student.backend.employee.dto.response.EmployeeDetailsResponse;
import com.student.backend.employee.dto.response.EmployeeRoleOptionResponse;
import com.student.backend.identity.domain.model.Credential;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.model.UserRole;
import com.student.backend.identity.domain.repository.CredentialRepository;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.identity.domain.repository.UserRoleRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.Deque;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetEmployeeDetailsUseCase {

    private final UserRepository userRepository;
    private final CredentialRepository credentialRepository;
    private final UserRoleRepository userRoleRepository;
    private final RoleRepository roleRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final DepartmentRepository departmentRepository;
    private final EmployeeAccessService employeeAccessService;

    @Transactional(readOnly = true)
    public EmployeeDetailsResponse get(UUID employeeId, UUID currentUserId) {
        validateRequest(employeeId, currentUserId);

        Department currentUserDepartment = employeeAccessService.getSingleActiveDepartment(currentUserId);

        User employee = userRepository.findById(employeeId)
                .orElseThrow(() -> new NotFoundException("Сотрудник не найден"));

        Credential credential = credentialRepository.findById(employeeId)
                .orElseThrow(() -> new NotFoundException("Учетные данные сотрудника не найдены"));

        UserRole employeeUserRole = userRoleRepository.findFirstByUser_UserId(employeeId)
                .orElseThrow(() -> new NotFoundException("Для сотрудника не назначена роль"));

        Role employeeRole = roleRepository.findById(employeeUserRole.getRoleId())
                .orElseThrow(() -> new NotFoundException("Роль сотрудника не найдена"));

        DepartmentUser employeeDepartmentUser = departmentUserRepository.findFirstByUserId(employeeId)
                .orElseThrow(() -> new NotFoundException("Сотрудник не привязан к подразделению"));

        Department employeeDepartment = employeeDepartmentUser.getDepartment();

        if (employeeDepartment == null) {
            throw new NotFoundException("Подразделение сотрудника не найдено");
        }

        if (!isDepartmentInsideRoot(employeeDepartment, currentUserDepartment)) {
            throw new BadRequestException("Ваш уровень доступа не позволяет открыть карточку этого сотрудника");
        }

        List<Department> activeAvailableDepartments = collectActiveAvailableDepartments(currentUserDepartment);
        List<EmployeeDepartmentOptionResponse> departments = buildDepartmentOptions(
                activeAvailableDepartments,
                employeeDepartment
        );

        List<EmployeeRoleOptionResponse> roles = buildRoleOptions(employeeRole);

        return EmployeeDetailsResponse.builder()
                .employee(EmployeeDetailsItemResponse.builder()
                        .userId(employee.getUserId())
                        .lastName(employee.getLastName())
                        .firstName(employee.getFirstName())
                        .middleName(employee.getMiddleName())
                        .fullName(buildFullName(employee))
                        .login(credential.getLogin())
                        .roleId(employeeRole.getRoleId())
                        .roleName(employeeRole.getName())
                        .roleIsActive(employeeRole.getIsActive())
                        .departmentId(employeeDepartment.getDepartmentId())
                        .departmentName(employeeDepartment.getName())
                        .departmentIsActive(employeeDepartment.isActive())
                        .isActive(employee.getIsActive())
                        .build())
                .roles(roles)
                .departments(departments)
                .build();
    }

    private void validateRequest(UUID employeeId, UUID currentUserId) {
        if (employeeId == null) {
            throw new BadRequestException("employeeId обязателен");
        }

        if (currentUserId == null) {
            throw new BadRequestException("userId обязателен");
        }
    }

    /**
     * Проверяем доступ не через список активных подразделений,
     * а через подъем от подразделения сотрудника вверх по parentDepartment.
     *
     * Это нужно, чтобы карточка не ломалась, если текущее подразделение сотрудника
     * стало неактивным, но исторически находится внутри ветки текущего пользователя.
     */
    private boolean isDepartmentInsideRoot(Department employeeDepartment, Department rootDepartment) {
        if (employeeDepartment == null || rootDepartment == null) {
            return false;
        }

        UUID rootDepartmentId = rootDepartment.getDepartmentId();
        Department current = employeeDepartment;

        while (current != null) {
            if (rootDepartmentId.equals(current.getDepartmentId())) {
                return true;
            }

            current = current.getParentDepartment();
        }

        return false;
    }

    /**
     * Для выбора в форме редактирования возвращаем только активные подразделения
     * из ветки текущего пользователя.
     *
     * Неактивные подразделения здесь специально не собираем,
     * чтобы не засорять select.
     */
    private List<Department> collectActiveAvailableDepartments(Department rootDepartment) {
        Map<UUID, Department> result = new LinkedHashMap<>();
        Deque<Department> queue = new ArrayDeque<>();
        queue.add(rootDepartment);

        while (!queue.isEmpty()) {
            Department current = queue.poll();

            if (current == null || current.getDepartmentId() == null) {
                continue;
            }

            if (result.containsKey(current.getDepartmentId())) {
                continue;
            }

            result.put(current.getDepartmentId(), current);

            List<Department> children = departmentRepository
                    .findAllByParentDepartment_DepartmentIdAndIsActiveTrueOrderByNameAsc(current.getDepartmentId());

            queue.addAll(children);
        }

        List<Department> departments = new ArrayList<>(result.values());

        departments.sort(
                Comparator
                        .comparing(Department::getHierarchyLevel, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(department -> normalizeForSort(department.getName()))
                        .thenComparing(department -> department.getDepartmentId().toString())
        );

        return departments;
    }

    /**
     * В response departments добавляем:
     * 1. все активные доступные подразделения;
     * 2. плюс текущее подразделение сотрудника, если его нет в списке.
     *
     * Обычно это нужно для случая, когда текущее подразделение сотрудника неактивно.
     */
    private List<EmployeeDepartmentOptionResponse> buildDepartmentOptions(
            List<Department> activeAvailableDepartments,
            Department employeeDepartment
    ) {
        Map<UUID, Department> departmentById = new LinkedHashMap<>();

        for (Department department : activeAvailableDepartments) {
            departmentById.put(department.getDepartmentId(), department);
        }

        if (employeeDepartment != null && employeeDepartment.getDepartmentId() != null) {
            departmentById.putIfAbsent(employeeDepartment.getDepartmentId(), employeeDepartment);
        }

        return departmentById.values().stream()
                .sorted(
                        Comparator
                                .comparing(Department::getHierarchyLevel, Comparator.nullsLast(Integer::compareTo))
                                .thenComparing(department -> normalizeForSort(department.getName()))
                                .thenComparing(department -> department.getDepartmentId().toString())
                )
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

    /**
     * В response roles добавляем:
     * 1. все активные роли;
     * 2. плюс текущую роль сотрудника, если она неактивна.
     */
    private List<EmployeeRoleOptionResponse> buildRoleOptions(Role employeeRole) {
        Map<UUID, Role> roleById = new LinkedHashMap<>();

        List<Role> activeRoles = roleRepository.findAllByIsActiveTrueOrderByNameAsc();

        for (Role role : activeRoles) {
            roleById.put(role.getRoleId(), role);
        }

        if (employeeRole != null && employeeRole.getRoleId() != null) {
            roleById.putIfAbsent(employeeRole.getRoleId(), employeeRole);
        }

        return roleById.values().stream()
                .sorted(
                        Comparator
                                .comparing((Role role) -> Boolean.TRUE.equals(role.getIsActive()) ? 0 : 1)
                                .thenComparing(role -> normalizeForSort(role.getName()))
                                .thenComparing(role -> role.getRoleId().toString())
                )
                .map(role -> EmployeeRoleOptionResponse.builder()
                        .roleId(role.getRoleId())
                        .name(role.getName())
                        .description(role.getDescription())
                        .isActive(role.getIsActive())
                        .build())
                .toList();
    }

    private String normalizeForSort(String value) {
        if (value == null) {
            return "";
        }

        return value.trim().toLowerCase();
    }

    private String buildFullName(User user) {
        StringBuilder fullName = new StringBuilder();

        if (user.getLastName() != null && !user.getLastName().isBlank()) {
            fullName.append(user.getLastName().trim());
        }

        if (user.getFirstName() != null && !user.getFirstName().isBlank()) {
            if (!fullName.isEmpty()) {
                fullName.append(" ");
            }
            fullName.append(user.getFirstName().trim());
        }

        if (user.getMiddleName() != null && !user.getMiddleName().isBlank()) {
            if (!fullName.isEmpty()) {
                fullName.append(" ");
            }
            fullName.append(user.getMiddleName().trim());
        }

        return fullName.toString();
    }
}
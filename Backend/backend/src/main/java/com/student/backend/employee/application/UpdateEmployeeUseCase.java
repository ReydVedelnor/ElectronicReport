package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.employee.dto.request.UpdateEmployeeRequest;
import com.student.backend.employee.dto.response.CreateEmployeeResponse;
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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayDeque;
import java.util.Deque;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.Objects;

@Service
@RequiredArgsConstructor
public class UpdateEmployeeUseCase {

    private final UserRepository userRepository;
    private final CredentialRepository credentialRepository;
    private final UserRoleRepository userRoleRepository;
    private final RoleRepository roleRepository;
    private final DepartmentRepository departmentRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmployeeAccessService employeeAccessService;

    @Transactional
    public CreateEmployeeResponse update(UUID employeeId, UpdateEmployeeRequest request) {
        validateRequest(employeeId, request);

        Department updaterDepartment = employeeAccessService.getSingleActiveDepartment(request.getUpdatedByUserId());

        User employee = userRepository.findById(employeeId)
                .orElseThrow(() -> new NotFoundException("Сотрудник не найден"));

        Credential credential = credentialRepository.findById(employeeId)
                .orElseThrow(() -> new NotFoundException("Учетные данные сотрудника не найдены"));

        UserRole currentUserRole = userRoleRepository.findFirstByUser_UserId(employeeId)
                .orElseThrow(() -> new NotFoundException("Для сотрудника не назначена роль"));

        DepartmentUser currentDepartmentUser = departmentUserRepository.findFirstByUserId(employeeId)
                .orElseThrow(() -> new NotFoundException("Сотрудник не привязан к подразделению"));

        Department currentDepartment = currentDepartmentUser.getDepartment();
        if (currentDepartment == null) {
            throw new NotFoundException("Текущее подразделение сотрудника не найдено");
        }

        if (!isDepartmentInsideRoot(currentDepartment, updaterDepartment)) {
            throw new BadRequestException("Ваш уровень доступа не позволяет редактировать этого сотрудника");
        }

        boolean changed = false;

        if (request.getLastName() != null) {
            String newLastName = request.getLastName().trim();
            if (newLastName.isEmpty()) {
                throw new BadRequestException("lastName не может быть пустым");
            }
            if (!newLastName.equals(employee.getLastName())) {
                employee.setLastName(newLastName);
                changed = true;
            }
        }

        if (request.getFirstName() != null) {
            String newFirstName = request.getFirstName().trim();
            if (newFirstName.isEmpty()) {
                throw new BadRequestException("firstName не может быть пустым");
            }
            if (!newFirstName.equals(employee.getFirstName())) {
                employee.setFirstName(newFirstName);
                changed = true;
            }
        }

        if (request.getMiddleName() != null) {
            String newMiddleName = normalizeNullable(request.getMiddleName());
            String currentMiddleName = normalizeNullable(employee.getMiddleName());

            if (!equalsNullable(currentMiddleName, newMiddleName)) {
                employee.setMiddleName(newMiddleName);
                changed = true;
            }
        }

        if (request.getLogin() != null) {
            String newLogin = request.getLogin().trim();
            if (newLogin.isEmpty()) {
                throw new BadRequestException("login не может быть пустым");
            }
            if (newLogin.length() > 150) {
                throw new BadRequestException("login не должен быть длиннее 150 символов");
            }

            if (!newLogin.equals(credential.getLogin())) {
                if (credentialRepository.existsByLogin(newLogin)) {
                    throw new BadRequestException("Логин уже занят");
                }
                credential.setLogin(newLogin);
                changed = true;
            }
        }

        if (request.getPassword() != null) {
            if (request.getPassword().isBlank()) {
                throw new BadRequestException("password не может быть пустым");
            }
            if (request.getPassword().length() < 3) {
                throw new BadRequestException("password должен содержать минимум 3 символа");
            }

            String encodedPassword = passwordEncoder.encode(request.getPassword());
            credential.setPasswordHash(encodedPassword);
            changed = true;
        }

        if (request.getIsActive() != null) {
            if (!request.getIsActive().equals(employee.getIsActive())) {
                employee.setIsActive(request.getIsActive());
                changed = true;
            }
        }

        if (request.getRoleId() != null && !request.getRoleId().equals(currentUserRole.getRoleId())) {
            Role newRole = roleRepository.findByRoleIdAndIsActiveTrue(request.getRoleId())
                    .orElseThrow(() -> new NotFoundException("Роль не найдена или неактивна"));

            userRoleRepository.delete(currentUserRole);

            UserRole newUserRole = new UserRole();
            newUserRole.setUserId(employeeId);
            newUserRole.setRoleId(newRole.getRoleId());
            userRoleRepository.save(newUserRole);

            currentUserRole = newUserRole;
            changed = true;
        }

        if (request.getDepartmentId() != null && !request.getDepartmentId().equals(currentDepartment.getDepartmentId())) {
            Department newDepartment = departmentRepository.findById(request.getDepartmentId())
                    .orElseThrow(() -> new NotFoundException("Подразделение не найдено"));

            if (!isDepartmentInsideRoot(newDepartment, updaterDepartment)) {
                throw new BadRequestException("Ваш уровень доступа не позволяет перевести сотрудника в выбранное подразделение");
            }

            if (!newDepartment.isActive()) {
                throw new BadRequestException("Нельзя перевести сотрудника в неактивное подразделение");
            }

            departmentUserRepository.delete(currentDepartmentUser);

            DepartmentUser newDepartmentUser = new DepartmentUser();
            newDepartmentUser.setDepartmentId(newDepartment.getDepartmentId());
            newDepartmentUser.setUserId(employeeId);
            departmentUserRepository.save(newDepartmentUser);

            currentDepartment = newDepartment;
            changed = true;
        }

        if (changed) {
            userRepository.save(employee);
            credentialRepository.save(credential);
        }

        Role responseRole = roleRepository.findById(currentUserRole.getRoleId())
                .orElseThrow(() -> new NotFoundException("Роль после обновления не найдена"));

        return CreateEmployeeResponse.builder()
                .userId(employee.getUserId())
                .fullName(buildFullName(employee))
                .login(credential.getLogin())
                .roleId(responseRole.getRoleId())
                .roleName(responseRole.getName())
                .departmentId(currentDepartment.getDepartmentId())
                .departmentName(currentDepartment.getName())
                .isActive(employee.getIsActive())
                .message(changed ? "Сотрудник успешно обновлен" : "Изменений не обнаружено")
                .build();
    }

    private void validateRequest(UUID employeeId, UpdateEmployeeRequest request) {
        if (employeeId == null) {
            throw new BadRequestException("employeeId обязателен");
        }

        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }

        if (request.getUpdatedByUserId() == null) {
            throw new BadRequestException("updatedByUserId обязателен");
        }
    }

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

    private String normalizeNullable(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private boolean equalsNullable(String left, String right) {
        if (left == null) {
            return right == null;
        }
        return left.equals(right);
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
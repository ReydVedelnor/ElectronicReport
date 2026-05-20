package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.employee.dto.request.CreateEmployeeRequest;
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
import java.security.SecureRandom;

@Service
@RequiredArgsConstructor
public class CreateEmployeeUseCase {

    private final UserRepository userRepository;
    private final CredentialRepository credentialRepository;
    private final UserRoleRepository userRoleRepository;
    private final RoleRepository roleRepository;
    private final DepartmentRepository departmentRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmployeeAccessService employeeAccessService;  // Для недублирования кода

    // Для пароля
    private static final String PASSWORD_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789";
    private static final int GENERATED_PASSWORD_LENGTH = 6;
    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    @Transactional
    public CreateEmployeeResponse create(CreateEmployeeRequest request) {
        validateRequest(request);

        // Для недублирования кода
        Department creatorDepartment = employeeAccessService.getSingleActiveDepartment(request.getCreatedByUserId());
        Set<UUID> availableDepartmentIds = collectAvailableDepartmentIds(creatorDepartment);

        if (!availableDepartmentIds.contains(request.getDepartmentId())) {
            throw new BadRequestException("Ваш уровень доступа не позволяет создать пользователя в выбранном подразделении");
        }

        Department targetDepartment = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new NotFoundException("Подразделение не найдено"));

        if (!targetDepartment.isActive()) {
            throw new BadRequestException("Подразделение неактивно");
        }

        Role role = roleRepository.findByRoleIdAndIsActiveTrue(request.getRoleId())
                .orElseThrow(() -> new NotFoundException("Роль не найдена или неактивна"));

        String normalizedLogin = request.getLogin().trim();
        if (credentialRepository.existsByLogin(normalizedLogin)) {
            throw new BadRequestException("Логин уже занят");
        }

        User user = User.builder()
                .lastName(request.getLastName().trim())
                .firstName(request.getFirstName().trim())
                .middleName(normalizeNullable(request.getMiddleName()))
                .isActive(true)
                .build();

        user = userRepository.save(user);

        String generatedPassword = generatePassword();

        Credential credential = Credential.builder()
                .user(user)
                .login(normalizedLogin)
                .passwordHash(passwordEncoder.encode(generatedPassword))
                .failedLoginAttempts(0)
                .build();

        credentialRepository.save(credential);

        DepartmentUser departmentUser = new DepartmentUser();
        departmentUser.setDepartmentId(targetDepartment.getDepartmentId());
        departmentUser.setUserId(user.getUserId());
        departmentUserRepository.save(departmentUser);

        UserRole userRole = new UserRole();
        userRole.setUserId(user.getUserId());
        userRole.setRoleId(role.getRoleId());
        userRoleRepository.save(userRole);

        return CreateEmployeeResponse.builder()
                .userId(user.getUserId())
                .fullName(buildFullName(user))
                .login(normalizedLogin)
                .roleId(role.getRoleId())
                .roleName(role.getName())
                .departmentId(targetDepartment.getDepartmentId())
                .departmentName(targetDepartment.getName())
                .generatedPassword(generatedPassword)
                .isActive(user.getIsActive())
                .message("Сотрудник успешно создан")
                .build();
    }

    private void validateRequest(CreateEmployeeRequest request) {
        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }

        if (request.getCreatedByUserId() == null) {
            throw new BadRequestException("createdByUserId обязателен");
        }

        if (request.getLastName() == null || request.getLastName().isBlank()) {
            throw new BadRequestException("lastName обязателен");
        }

        if (request.getFirstName() == null || request.getFirstName().isBlank()) {
            throw new BadRequestException("firstName обязателен");
        }

        if (request.getRoleId() == null) {
            throw new BadRequestException("roleId обязателен");
        }

        if (request.getDepartmentId() == null) {
            throw new BadRequestException("departmentId обязателен");
        }

        if (request.getLogin() == null || request.getLogin().isBlank()) {
            throw new BadRequestException("login обязателен");
        }

        if (request.getLogin().trim().length() > 150) {
            throw new BadRequestException("login не должен быть длиннее 150 символов");
        }
    }

    private Set<UUID> collectAvailableDepartmentIds(Department rootDepartment) {
        Set<UUID> result = new HashSet<>();
        Deque<Department> queue = new ArrayDeque<>();
        queue.add(rootDepartment);

        while (!queue.isEmpty()) {
            Department current = queue.poll();
            result.add(current.getDepartmentId());

            List<Department> children = departmentRepository
                    .findAllByParentDepartment_DepartmentIdAndIsActiveTrueOrderByNameAsc(current.getDepartmentId());

            queue.addAll(children);
        }

        return result;
    }

    private String normalizeNullable(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
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

    private String generatePassword() {
        StringBuilder password = new StringBuilder(GENERATED_PASSWORD_LENGTH);

        for (int i = 0; i < GENERATED_PASSWORD_LENGTH; i++) {
            int index = SECURE_RANDOM.nextInt(PASSWORD_ALPHABET.length());
            password.append(PASSWORD_ALPHABET.charAt(index));
        }

        return password.toString();
    }
}
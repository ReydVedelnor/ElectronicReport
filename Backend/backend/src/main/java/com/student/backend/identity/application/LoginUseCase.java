package com.student.backend.identity.application;

import com.fasterxml.jackson.databind.Module;
import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.Credential;
import com.student.backend.identity.domain.model.RoleModule;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.model.UserRole;
import com.student.backend.identity.domain.repository.CredentialRepository;
import com.student.backend.identity.domain.repository.RoleModuleRepository;
import com.student.backend.identity.domain.repository.UserRoleRepository;
import com.student.backend.identity.dto.request.LoginRequest;
import com.student.backend.identity.dto.response.LoginModuleResponse;
import com.student.backend.identity.dto.response.LoginResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Comparator;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class LoginUseCase {

    private final CredentialRepository credentialRepository;
    private final PasswordEncoder passwordEncoder;
    private final CredentialAuditService credentialAuditService;
    private final UserRoleRepository userRoleRepository;

    // Для ответа с ролями
    private static final Map<String, Integer> MODULE_ORDER = Map.of(
            "HOME", 1,
            "SHIFT_REPORTS", 2,
            "TEMPLATES", 3,
            "ANALYTICS", 4,
            "EMPLOYEES", 5,
            "ORG_STRUCTURE", 6,
            "ROLES", 7
    );
    private final RoleModuleRepository roleModuleRepository;

    public LoginResponse login(LoginRequest request) {
        validateRequest(request);

        Credential credential = credentialRepository.findByLogin(request.getLogin().trim())
                .orElseThrow(() -> new NotFoundException("Пользователь с таким логином не найден"));

        User user = credential.getUser();
        if (user == null) {
            throw new NotFoundException("Пользователь для учетных данных не найден");
        }

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new BadRequestException("Пользователь неактивен");
        }

        boolean passwordMatches = passwordEncoder.matches(
                request.getPassword(),
                credential.getPasswordHash()
        );

        if (!passwordMatches) {
            credentialAuditService.increaseFailedLoginAttempts(user.getUserId());
            throw new BadRequestException("Неверный логин или пароль");
        }

        credentialAuditService.markSuccessfulLogin(user.getUserId());

        // Блок ролей
        UserRole userRole = userRoleRepository.findFirstByUser_UserId(user.getUserId())
                .orElseThrow((() -> new NotFoundException("Для пользователя не назначена роль")));

        if (userRole.getRole() == null){
            throw new NotFoundException("Роль пользователя существует в user_roles, но в role не найдена");
        }

        if (!Boolean.TRUE.equals(userRole.getRole().getIsActive())) {
            throw new BadRequestException("Роль пользователя неактивна");
        }

        // Формируем список доступных модулей для ответа
        List<LoginModuleResponse> modules = roleModuleRepository.findAllByRoleId(userRole.getRoleId())
                .stream()
                .map(RoleModule::getModule)
                .filter(module -> module != null && Boolean.TRUE.equals(module.getIsActive()))
                .sorted(Comparator.comparingInt(module -> MODULE_ORDER.getOrDefault(module.getSlug(), Integer.MAX_VALUE)))
                .map(module -> LoginModuleResponse.builder()
                        .slug(module.getSlug())
                        .displayName(module.getDisplayName())
                        .build())
                .toList();


        return LoginResponse.builder()
                .userId(user.getUserId())
                .login(credential.getLogin())
                .fullName(buildFullName(user))
                .roleId(userRole.getRole().getRoleId())
                .roleName(userRole.getRole().getName())
                .modules(modules)
                .message("Вход выполнен успешно")
                .build();
    }

    private void validateRequest(LoginRequest request) {
        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }

        if (request.getLogin() == null || request.getLogin().isBlank()) {
            throw new BadRequestException("login обязателен");
        }

        if (request.getPassword() == null || request.getPassword().isBlank()) {
            throw new BadRequestException("password обязателен");
        }
    }

    // Передадим на фронт ФИО целиком
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
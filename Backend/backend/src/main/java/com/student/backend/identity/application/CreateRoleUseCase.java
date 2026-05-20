package com.student.backend.identity.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.identity.domain.model.Module;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.model.RoleModule;
import com.student.backend.identity.domain.repository.ModuleRepository;
import com.student.backend.identity.domain.repository.RoleModuleRepository;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.identity.dto.request.CreateRoleRequest;
import com.student.backend.identity.dto.response.CreateRoleResponse;
import com.student.backend.identity.dto.response.RoleDetailsModuleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CreateRoleUseCase {

    private final RoleRepository roleRepository;
    private final ModuleRepository moduleRepository;
    private final RoleModuleRepository roleModuleRepository;

    @Transactional
    public CreateRoleResponse create(CreateRoleRequest request) {
        validateRequest(request);

        String normalizedName = request.getName().trim();
        String normalizedDescription = normalizeNullable(request.getDescription());

        if (roleRepository.existsByNameIgnoreCase(normalizedName)) {
            throw new BadRequestException("Роль с таким названием уже существует");
        }

        Set<UUID> uniqueModuleIds = normalizeModuleIds(request.getModuleIds());
        List<Module> modules = findAndValidateModules(uniqueModuleIds);

        Role role = Role.builder()
                .name(normalizedName)
                .description(normalizedDescription)
                .isActive(true)
                .build();

        role = roleRepository.save(role);

        saveRoleModules(role.getRoleId(), modules);

        List<RoleDetailsModuleResponse> moduleResponses = modules.stream()
                .sorted(
                        Comparator
                                .comparing((Module module) -> normalizeForSort(module.getDisplayName()))
                                .thenComparing(module -> normalizeForSort(module.getSlug()))
                )
                .map(module -> RoleDetailsModuleResponse.builder()
                        .moduleId(module.getModuleId())
                        .slug(module.getSlug())
                        .displayName(module.getDisplayName())
                        .description(module.getDescription())
                        .isEnabled(true)
                        .build())
                .toList();

        return CreateRoleResponse.builder()
                .roleId(role.getRoleId())
                .name(role.getName())
                .description(role.getDescription())
                .isActive(role.getIsActive())
                .participantsCount(0L)
                .modules(moduleResponses)
                .message(moduleResponses.isEmpty() ? "Роль создана без модулей" : "Роль успешно создана")
                .build();
    }

    private void validateRequest(CreateRoleRequest request) {
        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }

        if (request.getName() == null || request.getName().isBlank()) {
            throw new BadRequestException("name обязателен");
        }

        if (request.getName().trim().length() > 100) {
            throw new BadRequestException("name не должен быть длиннее 100 символов");
        }
    }

    private Set<UUID> normalizeModuleIds(List<UUID> moduleIds) {
        Set<UUID> result = new LinkedHashSet<>();

        if (moduleIds == null || moduleIds.isEmpty()) {
            return result;
        }

        for (UUID moduleId : moduleIds) {
            if (moduleId != null) {
                result.add(moduleId);
            }
        }

        return result;
    }

    private List<Module> findAndValidateModules(Set<UUID> moduleIds) {
        if (moduleIds.isEmpty()) {
            return List.of();
        }

        List<Module> modules = moduleRepository.findAllByModuleIdInAndIsActiveTrue(moduleIds);

        if (modules.size() != moduleIds.size()) {
            throw new BadRequestException("Один или несколько модулей не найдены или неактивны");
        }

        return new ArrayList<>(modules);
    }

    private void saveRoleModules(UUID roleId, List<Module> modules) {
        if (modules == null || modules.isEmpty()) {
            return;
        }

        List<RoleModule> roleModules = modules.stream()
                .map(module -> {
                    RoleModule roleModule = new RoleModule();
                    roleModule.setRoleId(roleId);
                    roleModule.setModuleId(module.getModuleId());
                    return roleModule;
                })
                .toList();

        roleModuleRepository.saveAll(roleModules);
    }

    private String normalizeNullable(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }

        return value.trim();
    }

    private String normalizeForSort(String value) {
        if (value == null) {
            return "";
        }

        return value.trim().toLowerCase(Locale.ROOT);
    }
}
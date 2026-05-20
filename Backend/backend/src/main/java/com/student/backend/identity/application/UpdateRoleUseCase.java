package com.student.backend.identity.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.Module;
import com.student.backend.identity.domain.model.Role;
import com.student.backend.identity.domain.model.RoleModule;
import com.student.backend.identity.domain.repository.ModuleRepository;
import com.student.backend.identity.domain.repository.RoleModuleRepository;
import com.student.backend.identity.domain.repository.RoleRepository;
import com.student.backend.identity.domain.repository.UserRoleRepository;
import com.student.backend.identity.dto.request.UpdateRoleRequest;
import com.student.backend.identity.dto.response.RoleDetailsModuleResponse;
import com.student.backend.identity.dto.response.UpdateRoleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class UpdateRoleUseCase {

    private final RoleRepository roleRepository;
    private final ModuleRepository moduleRepository;
    private final RoleModuleRepository roleModuleRepository;
    private final UserRoleRepository userRoleRepository;

    @Transactional
    public UpdateRoleResponse update(UUID roleId, UpdateRoleRequest request) {
        validateRequest(roleId, request);

        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new NotFoundException("Роль не найдена"));

        boolean changed = false;
        boolean moduleIdsWereProvided = request.getModuleIds() != null;

        if (request.getName() != null) {
            String normalizedName = normalizeRequiredName(request.getName());

            if (!normalizedName.equals(role.getName())) {
                if (roleRepository.existsByNameIgnoreCaseAndRoleIdNot(normalizedName, role.getRoleId())) {
                    throw new BadRequestException("Роль с таким названием уже существует");
                }

                role.setName(normalizedName);
                changed = true;
            }
        }

        if (request.getDescription() != null) {
            String normalizedDescription = normalizeNullable(request.getDescription());

            if (!equalsNullable(role.getDescription(), normalizedDescription)) {
                role.setDescription(normalizedDescription);
                changed = true;
            }
        }

        if (request.getIsActive() != null) {
            if (!Objects.equals(role.getIsActive(), request.getIsActive())) {
                role.setIsActive(request.getIsActive());
                changed = true;
            }
        }

        if (moduleIdsWereProvided) {
            boolean modulesChanged = replaceModulesIfChanged(role.getRoleId(), request.getModuleIds());
            if (modulesChanged) {
                changed = true;
            }
        }

        if (changed) {
            roleRepository.save(role);
        }

        Set<UUID> enabledModuleIds = findEnabledModuleIds(role.getRoleId());
        List<RoleDetailsModuleResponse> modules = buildAllActiveModuleResponses(enabledModuleIds);
        long participantsCount = userRoleRepository.countActiveParticipantsByRoleId(role.getRoleId());

        return UpdateRoleResponse.builder()
                .roleId(role.getRoleId())
                .name(role.getName())
                .description(role.getDescription())
                .isActive(role.getIsActive())
                .participantsCount(participantsCount)
                .modules(modules)
                .message(buildMessage(changed, moduleIdsWereProvided, enabledModuleIds))
                .build();
    }

    private void validateRequest(UUID roleId, UpdateRoleRequest request) {
        if (roleId == null) {
            throw new BadRequestException("roleId обязателен");
        }

        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }
    }

    private String normalizeRequiredName(String value) {
        String normalized = value.trim();

        if (normalized.isEmpty()) {
            throw new BadRequestException("name не может быть пустым");
        }

        if (normalized.length() > 100) {
            throw new BadRequestException("name не должен быть длиннее 100 символов");
        }

        return normalized;
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

    private boolean replaceModulesIfChanged(UUID roleId, List<UUID> rawModuleIds) {
        Set<UUID> newModuleIds = normalizeModuleIds(rawModuleIds);
        List<Module> newModules = findAndValidateModules(newModuleIds);

        List<RoleModule> currentRoleModules = roleModuleRepository.findAllByRoleId(roleId);
        Set<UUID> currentModuleIds = currentRoleModules.stream()
                .map(RoleModule::getModuleId)
                .collect(LinkedHashSet::new, LinkedHashSet::add, LinkedHashSet::addAll);

        if (currentModuleIds.equals(newModuleIds)) {
            return false;
        }

        if (!currentRoleModules.isEmpty()) {
            roleModuleRepository.deleteAll(currentRoleModules);
        }

        if (!newModules.isEmpty()) {
            List<RoleModule> newRoleModules = newModules.stream()
                    .map(module -> {
                        RoleModule roleModule = new RoleModule();
                        roleModule.setRoleId(roleId);
                        roleModule.setModuleId(module.getModuleId());
                        return roleModule;
                    })
                    .toList();

            roleModuleRepository.saveAll(newRoleModules);
        }

        return true;
    }

    private Set<UUID> normalizeModuleIds(Collection<UUID> moduleIds) {
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

        return modules;
    }

    private Set<UUID> findEnabledModuleIds(UUID roleId) {
        return roleModuleRepository.findAllByRoleId(roleId).stream()
                .map(RoleModule::getModuleId)
                .collect(LinkedHashSet::new, LinkedHashSet::add, LinkedHashSet::addAll);
    }

    private List<RoleDetailsModuleResponse> buildAllActiveModuleResponses(Set<UUID> enabledModuleIds) {
        List<Module> activeModules = moduleRepository.findAllByIsActiveTrueOrderByDisplayNameAscSlugAsc();

        return activeModules.stream()
                .map(module -> RoleDetailsModuleResponse.builder()
                        .moduleId(module.getModuleId())
                        .slug(module.getSlug())
                        .displayName(module.getDisplayName())
                        .description(module.getDescription())
                        .isEnabled(enabledModuleIds.contains(module.getModuleId()))
                        .build())
                .toList();
    }

    private String buildMessage(boolean changed, boolean moduleIdsWereProvided, Set<UUID> enabledModuleIds) {
        if (!changed) {
            return "Изменений не обнаружено";
        }

        if (moduleIdsWereProvided && enabledModuleIds.isEmpty()) {
            return "Роль обновлена без модулей";
        }

        return "Роль успешно обновлена";
    }
}
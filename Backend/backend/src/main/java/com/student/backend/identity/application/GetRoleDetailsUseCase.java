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
import com.student.backend.identity.dto.response.RoleDetailsModuleResponse;
import com.student.backend.identity.dto.response.RoleDetailsResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetRoleDetailsUseCase {

    private final RoleRepository roleRepository;
    private final ModuleRepository moduleRepository;
    private final RoleModuleRepository roleModuleRepository;
    private final UserRoleRepository userRoleRepository;

    @Transactional(readOnly = true)
    public RoleDetailsResponse get(UUID roleId) {
        validateRoleId(roleId);

        Role role = roleRepository.findById(roleId)
                .orElseThrow(() -> new NotFoundException("Роль не найдена"));

        long participantsCount = userRoleRepository.countActiveParticipantsByRoleId(roleId);

        Set<UUID> enabledModuleIds = getEnabledModuleIds(roleId);

        List<RoleDetailsModuleResponse> modules = moduleRepository.findAllByIsActiveTrueOrderByDisplayNameAscSlugAsc()
                .stream()
                .map(module -> buildModuleResponse(module, enabledModuleIds))
                .toList();

        return RoleDetailsResponse.builder()
                .roleId(role.getRoleId())
                .name(role.getName())
                .description(role.getDescription())
                .isActive(role.getIsActive())
                .participantsCount(participantsCount)
                .modules(modules)
                .build();
    }

    private void validateRoleId(UUID roleId) {
        if (roleId == null) {
            throw new BadRequestException("roleId обязателен");
        }
    }

    private Set<UUID> getEnabledModuleIds(UUID roleId) {
        List<RoleModule> roleModules = roleModuleRepository.findAllByRoleId(roleId);

        Set<UUID> result = new HashSet<>();

        for (RoleModule roleModule : roleModules) {
            result.add(roleModule.getModuleId());
        }

        return result;
    }

    private RoleDetailsModuleResponse buildModuleResponse(Module module, Set<UUID> enabledModuleIds) {
        return RoleDetailsModuleResponse.builder()
                .moduleId(module.getModuleId())
                .slug(module.getSlug())
                .displayName(module.getDisplayName())
                .description(module.getDescription())
                .isEnabled(enabledModuleIds.contains(module.getModuleId()))
                .build();
    }
}
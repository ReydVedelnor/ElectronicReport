package com.student.backend.identity.application;

import com.student.backend.identity.domain.model.Module;
import com.student.backend.identity.domain.repository.ModuleRepository;
import com.student.backend.identity.dto.response.RoleCreateContextResponse;
import com.student.backend.identity.dto.response.RoleDetailsModuleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GetRoleCreateContextUseCase {

    private final ModuleRepository moduleRepository;

    @Transactional(readOnly = true)
    public RoleCreateContextResponse get() {
        List<Module> modules = moduleRepository.findAllByIsActiveTrueOrderByDisplayNameAscSlugAsc();

        List<RoleDetailsModuleResponse> moduleResponses = modules.stream()
                .map(module -> RoleDetailsModuleResponse.builder()
                        .moduleId(module.getModuleId())
                        .slug(module.getSlug())
                        .displayName(module.getDisplayName())
                        .description(module.getDescription())
                        .isEnabled(false)
                        .build())
                .toList();

        return RoleCreateContextResponse.builder()
                .modules(moduleResponses)
                .build();
    }
}
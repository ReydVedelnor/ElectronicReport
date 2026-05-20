package com.student.backend.identity.api;

import org.springframework.web.bind.annotation.*;

import com.student.backend.identity.application.GetRoleListUseCase;
import com.student.backend.identity.dto.request.GetRoleListRequest;
import com.student.backend.identity.dto.response.RoleListResponse;
import lombok.RequiredArgsConstructor;
import com.student.backend.identity.application.GetRoleDetailsUseCase;
import com.student.backend.identity.dto.response.RoleDetailsResponse;

import com.student.backend.identity.application.GetRoleCreateContextUseCase;
import com.student.backend.identity.dto.response.RoleCreateContextResponse;

import com.student.backend.identity.application.CreateRoleUseCase;
import com.student.backend.identity.dto.request.CreateRoleRequest;
import com.student.backend.identity.dto.response.CreateRoleResponse;

import com.student.backend.identity.application.UpdateRoleUseCase;
import com.student.backend.identity.dto.request.UpdateRoleRequest;
import com.student.backend.identity.dto.response.UpdateRoleResponse;

import java.util.UUID;

@RestController
@RequestMapping("/api/roles")
@RequiredArgsConstructor
public class RoleController {

    private final GetRoleListUseCase getRoleListUseCase;
    private final GetRoleDetailsUseCase getRoleDetailsUseCase;
    private final GetRoleCreateContextUseCase getRoleCreateContextUseCase;
    private final CreateRoleUseCase createRoleUseCase;
    private final UpdateRoleUseCase updateRoleUseCase;

    // Базовый эндпоинт. Возвращает список с количеством назначенных сотрудников
    @GetMapping
    public RoleListResponse getRoles(@ModelAttribute GetRoleListRequest request) {
        return getRoleListUseCase.get(request);
    }

    // Для карточки роли
    @GetMapping("/{roleId}")
    public RoleDetailsResponse getRole(@PathVariable UUID roleId) {
        return getRoleDetailsUseCase.get(roleId);
    }



    // Получить список модулей (контекст для создания)
    @GetMapping("/create-context")
    public RoleCreateContextResponse getCreateContext() {
        return getRoleCreateContextUseCase.get();
    }

    // Создать роль
    @PostMapping("/create")
    public CreateRoleResponse create(@RequestBody CreateRoleRequest request) {
        return createRoleUseCase.create(request);
    }


    @PatchMapping("/{roleId}")
    public UpdateRoleResponse update(
            @PathVariable UUID roleId,
            @RequestBody UpdateRoleRequest request
    ) {
        return updateRoleUseCase.update(roleId, request);
    }
}
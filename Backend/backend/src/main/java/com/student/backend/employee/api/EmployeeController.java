package com.student.backend.employee.api;

import com.student.backend.employee.application.CreateEmployeeUseCase;
import com.student.backend.employee.application.GetEmployeeCreateContextUseCase;
import com.student.backend.employee.application.UpdateEmployeeUseCase;
import com.student.backend.employee.dto.request.CreateEmployeeRequest;
import com.student.backend.employee.dto.response.CreateEmployeeResponse;
import com.student.backend.employee.dto.response.EmployeeCreateContextResponse;
import com.student.backend.employee.dto.request.UpdateEmployeeRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import org.springframework.web.bind.annotation.ModelAttribute;
import com.student.backend.employee.application.GetEmployeeListUseCase;
import com.student.backend.employee.dto.request.GetEmployeeListRequest;
import com.student.backend.employee.dto.response.EmployeeListResponse;

import com.student.backend.employee.application.GetEmployeeFilterContextUseCase;
import com.student.backend.employee.dto.response.EmployeeFilterContextResponse;

import com.student.backend.employee.application.GetEmployeeDetailsUseCase;
import com.student.backend.employee.dto.response.EmployeeDetailsResponse;

import java.util.UUID;

@RestController
@RequestMapping("/api/employees")
@RequiredArgsConstructor
public class EmployeeController {

    private final GetEmployeeCreateContextUseCase getEmployeeCreateContextUseCase;
    private final CreateEmployeeUseCase createEmployeeUseCase;

    // Для поиска
    private final GetEmployeeListUseCase getEmployeeListUseCase;
    // Для фильтров
    private final GetEmployeeFilterContextUseCase getEmployeeFilterContextUseCase;
    // Для карточки сотрудника
    private final GetEmployeeDetailsUseCase getEmployeeDetailsUseCase;
    // Для редактирования
    private final UpdateEmployeeUseCase updateEmployeeUseCase;

    @GetMapping("/create-context")
    public EmployeeCreateContextResponse getCreateContext(@RequestParam UUID userId) {
        return getEmployeeCreateContextUseCase.get(userId);
    }

    @PostMapping("/create")
    public CreateEmployeeResponse create(@RequestBody CreateEmployeeRequest request) {
        return createEmployeeUseCase.create(request);
    }

    // Редактирование
    @PatchMapping("/{employeeId}")
    public CreateEmployeeResponse update(
            @PathVariable UUID employeeId,
            @RequestBody UpdateEmployeeRequest request
    ) {
        return updateEmployeeUseCase.update(employeeId, request);
    }

    // Поиск
    @GetMapping
    public EmployeeListResponse getEmployees(@ModelAttribute GetEmployeeListRequest request) {
        return getEmployeeListUseCase.get(request);
    }

    // Фильтр
    @GetMapping("/filter-context")
    public EmployeeFilterContextResponse getFilterContext(@RequestParam UUID userId) {
        return getEmployeeFilterContextUseCase.get(userId);
    }

    // Карточка сотрудника
    @GetMapping("/{employeeId}")
    public EmployeeDetailsResponse getEmployeeDetails(
            @PathVariable UUID employeeId,
            @RequestParam UUID userId
    ) {
        return getEmployeeDetailsUseCase.get(employeeId, userId);
    }
}
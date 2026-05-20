package com.student.backend.employee.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentUserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class EmployeeAccessService {

    private final UserRepository userRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final DepartmentRepository departmentRepository;

    public Department getSingleActiveDepartment(UUID userId) {
        if (userId == null) {
            throw new BadRequestException("userId обязателен");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new BadRequestException("Пользователь неактивен");
        }

        List<DepartmentUser> departmentUsers = departmentUserRepository.findAllByUserId(userId);

        if (departmentUsers.isEmpty()) {
            throw new BadRequestException("Пользователь не привязан ни к одному подразделению");
        }

        if (departmentUsers.size() > 1) {
            throw new BadRequestException("Пользователь привязан к нескольким подразделениям. Требуется уточнение логики выбора");
        }

        Department department = departmentUsers.getFirst().getDepartment();

        if (department == null) {
            throw new NotFoundException("Подразделение пользователя не найдено");
        }

        if (!department.isActive()) {
            throw new BadRequestException("Подразделение пользователя неактивно");
        }

        return department;
    }
}
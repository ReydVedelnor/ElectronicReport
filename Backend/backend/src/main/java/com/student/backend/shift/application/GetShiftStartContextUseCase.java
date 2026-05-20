// валидирует userId
// ищет пользователя
// проверяет, что пользователь активен
// ищет department через department_users
// проверяет, что department активен
// загружает schedules департамента
// сортирует по sortOrder
// отдаёт DTO




package com.student.backend.shift.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.repository.DepartmentScheduleRepository;
import com.student.backend.organization.domain.repository.DepartmentUserRepository;
import com.student.backend.shift.dto.response.ShiftStartContextResponse;
import com.student.backend.shift.dto.response.ShiftStartScheduleItemResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetShiftStartContextUseCase {

    private final UserRepository userRepository;
    private final DepartmentUserRepository departmentUserRepository;
    private final DepartmentScheduleRepository departmentScheduleRepository;

    public ShiftStartContextResponse get(UUID userId) {
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
            throw new BadRequestException("Подразделение неактивно");
        }

        List<DepartmentSchedule> schedules =
                departmentScheduleRepository.findAllByDepartment_DepartmentIdOrderBySortOrderAsc(
                        department.getDepartmentId()
                );

        List<ShiftStartScheduleItemResponse> scheduleItems = schedules.stream()
                .map(schedule -> ShiftStartScheduleItemResponse.builder()
                        .scheduleId(schedule.getScheduleId())
                        .name(schedule.getName())
                        .sortOrder(schedule.getSortOrder())
                        .startTime(schedule.getStartTime())
                        .endTime(schedule.getEndTime())
                        .crossesMidnight(schedule.getCrossesMidnight())
                        .build())
                .toList();

        return ShiftStartContextResponse.builder()
                .engineerUserId(user.getUserId())
                .departmentId(department.getDepartmentId())
                .departmentName(department.getName())
                .schedules(scheduleItems)
                .build();
    }
}
package com.student.backend.shift.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.organization.domain.model.DepartmentTemplate;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentScheduleRepository;
import com.student.backend.organization.domain.repository.DepartmentTemplateRepository;
import com.student.backend.report.domain.enums.ReportStatus;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.shift.domain.enums.ShiftStatus;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.shift.domain.repository.ShiftRepository;
import com.student.backend.shift.dto.request.OpenShiftRequest;
import com.student.backend.shift.dto.response.OpenShiftResponse;
import com.student.backend.template.domain.model.ReportTemplate;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
@RequiredArgsConstructor
public class OpenShiftUseCase {

    private final ShiftRepository shiftRepository;
    private final ReportInstanceRepository reportInstanceRepository;

    private final DepartmentRepository departmentRepository;
    private final DepartmentScheduleRepository departmentScheduleRepository;
    private final DepartmentTemplateRepository departmentTemplateRepository;
    private final UserRepository userRepository;

    @Transactional
    public OpenShiftResponse open(OpenShiftRequest request) {
        validateRequest(request);

        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new NotFoundException("Подразделение не найдено"));

        if (!department.isActive()) {
            throw new BadRequestException("Подразделение неактивно");
        }

        DepartmentSchedule schedule = departmentScheduleRepository.findById(request.getScheduleId())
                .orElseThrow(() -> new NotFoundException("Расписание не найдено"));

        if (!schedule.getDepartment().getDepartmentId().equals(department.getDepartmentId())) {
            throw new BadRequestException("Расписание не принадлежит подразделению");
        }

        User engineer = userRepository.findById(request.getEngineerUserId())
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        if (!Boolean.TRUE.equals(engineer.getIsActive())) {
            throw new BadRequestException("Пользователь неактивен");
        }

        DepartmentTemplate departmentTemplate = departmentTemplateRepository
                .findFirstByDepartmentId(department.getDepartmentId())
                .orElseThrow(() -> new BadRequestException("Для подразделения не назначен шаблон"));

        ReportTemplate template = departmentTemplate.getTemplate();

        if (!Boolean.TRUE.equals(template.getIsActive())) {
            throw new BadRequestException("Шаблон отчета неактивен");
        }

        // Ищем предыдущую смену
        Shift previousShift = shiftRepository
                .findFirstByDepartment_DepartmentIdAndStartedAtBeforeOrderByStartedAtDesc(
                        department.getDepartmentId(),
                        request.getStartedAt()
                )
                .orElse(null);
        // Подготавливаем информацию о предыдущей смене для ответа
        boolean previousShiftFound = previousShift != null;
        UUID previousShiftId = previousShiftFound ? previousShift.getShiftId() : null;
        String previousShiftStatus = previousShiftFound ? previousShift.getStatus().name() : null;
        String previousShiftMessage = buildPreviousShiftMessage(previousShift);

        Shift shift = Shift.builder()
                .shiftId(UUID.randomUUID())
                .department(department)
                .schedule(schedule)
                .engineer(engineer)
                .startedAt(request.getStartedAt())
                .status(ShiftStatus.open)
                .build();

        shift = shiftRepository.save(shift);

        ReportInstance reportInstance = ReportInstance.builder()
                .reportId(UUID.randomUUID())
                .shift(shift)
                .template(template)
                .status(ReportStatus.not_ready)
                .build();

        reportInstance = reportInstanceRepository.save(reportInstance);

        return OpenShiftResponse.builder()
                .shiftId(shift.getShiftId())
                .reportId(reportInstance.getReportId())
                .templateId(template.getTemplateId())
                .templateName(template.getName())
                .shiftStatus(shift.getStatus().name())
                .reportStatus(reportInstance.getStatus().name())
                .startedAt(shift.getStartedAt())
                .departmentId(department.getDepartmentId())
                .scheduleId(schedule.getScheduleId())
                .engineerUserId(engineer.getUserId())
                .previousShiftFound(previousShiftFound)
                .previousShiftId(previousShiftId)
                .previousShiftStatus(previousShiftStatus)
                .previousShiftMessage(previousShiftMessage)
                .build();
    }

    private void validateRequest(OpenShiftRequest request) {
        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }
        if (request.getDepartmentId() == null) {
            throw new BadRequestException("departmentId обязателен");
        }
        if (request.getScheduleId() == null) {
            throw new BadRequestException("scheduleId обязателен");
        }
        if (request.getEngineerUserId() == null) {
            throw new BadRequestException("engineerUserId обязателен");
        }
        if (request.getStartedAt() == null) {
            throw new BadRequestException("startedAt обязателен");
        }
    }

    // Сообщение о предыдущей смене
    private String buildPreviousShiftMessage(Shift previousShift) {
        if (previousShift == null) {
            return "Предыдущая смена не найдена";
        }

        if (previousShift.getStatus() == ShiftStatus.open) {
            return "Предыдущая смена не завершена";
        }

        return "Предыдущая смена найдена и завершена";
    }
}
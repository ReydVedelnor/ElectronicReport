package com.student.backend.shift.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.report.domain.enums.ReportStatus;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.shift.domain.enums.ShiftStatus;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.shift.domain.repository.ShiftRepository;
import com.student.backend.shift.dto.response.WorkspaceCurrentReportResponse;
import com.student.backend.shift.dto.response.WorkspaceCurrentResponse;
import com.student.backend.shift.dto.response.WorkspaceCurrentShiftResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class GetCurrentWorkspaceUseCase {

    private static final ZoneOffset PROJECT_OFFSET = ZoneOffset.of("+05:00");
    private static final Duration MAX_SHIFT_DURATION = Duration.ofHours(23).plusMinutes(50);

    private final UserRepository userRepository;
    private final ShiftRepository shiftRepository;
    private final ReportInstanceRepository reportInstanceRepository;

    @Transactional
    public WorkspaceCurrentResponse execute(UUID userId) {
        if (userId == null) {
            throw new BadRequestException("userId обязателен");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));

        if (!Boolean.TRUE.equals(user.getIsActive())) {
            throw new BadRequestException("Пользователь неактивен");
        }

        Optional<Shift> openShiftOptional = shiftRepository
                .findFirstByEngineer_UserIdAndStatusOrderByStartedAtDesc(userId, ShiftStatus.open);

        if (openShiftOptional.isEmpty()) {
            return WorkspaceCurrentResponse.builder()
                    .workspaceStatus("NO_ACTIVE_SHIFT")
                    .autoClosed(false)
                    .autoCloseReason(null)
                    .message(null)
                    .shift(null)
                    .report(null)
                    .build();
        }

        Shift shift = openShiftOptional.get();
        OffsetDateTime now = OffsetDateTime.now(PROJECT_OFFSET);
        OffsetDateTime plannedEndAt = calculatePlannedEndAt(shift);

        boolean reachedScheduleEnd = !now.isBefore(plannedEndAt);
        boolean reachedMaxDuration = !now.isBefore(shift.getStartedAt().plus(MAX_SHIFT_DURATION));

        if (reachedScheduleEnd || reachedMaxDuration) {
            autoCloseShift(shift, now);

            String reason = reachedMaxDuration ? "MAX_DURATION_REACHED" : "SCHEDULE_END_REACHED";

            return WorkspaceCurrentResponse.builder()
                    .workspaceStatus("AUTO_CLOSED_SHIFT")
                    .autoClosed(true)
                    .autoCloseReason(reason)
                    .message("Предыдущая смена автоматически завершена")
                    .shift(null)
                    .report(null)
                    .build();
        }

        ReportInstance reportInstance = reportInstanceRepository.findByShift_ShiftId(shift.getShiftId())
                .orElse(null);

        return WorkspaceCurrentResponse.builder()
                .workspaceStatus("ACTIVE_SHIFT")
                .autoClosed(false)
                .autoCloseReason(null)
                .message(null)
                .shift(WorkspaceCurrentShiftResponse.builder()
                        .shiftId(shift.getShiftId())
                        .departmentId(shift.getDepartment().getDepartmentId())
                        .departmentName(shift.getDepartment().getName())
                        .scheduleId(shift.getSchedule().getScheduleId())
                        .scheduleName(shift.getSchedule().getName())
                        .startedAt(shift.getStartedAt())
                        .plannedEndAt(plannedEndAt)
                        .status(shift.getStatus().name())
                        .build())
                .report(reportInstance == null ? null : WorkspaceCurrentReportResponse.builder()
                        .reportId(reportInstance.getReportId())
                        .status(reportInstance.getStatus().name())
                        .build())
                .build();
    }

    private OffsetDateTime calculatePlannedEndAt(Shift shift) {
        LocalDate startDate = shift.getStartedAt()
                .atZoneSameInstant(PROJECT_OFFSET)
                .toLocalDate();

        LocalTime endTime = shift.getSchedule().getEndTime();
        boolean crossesMidnight = Boolean.TRUE.equals(shift.getSchedule().getCrossesMidnight());

        if (crossesMidnight) {
            return startDate.plusDays(1)
                    .atTime(endTime)
                    .atOffset(PROJECT_OFFSET);
        }

        return startDate.atTime(endTime).atOffset(PROJECT_OFFSET);
    }

    private void autoCloseShift(Shift shift, OffsetDateTime endedAt) {
        shift.setStatus(ShiftStatus.closed);
        shift.setEndedAt(endedAt);
        shiftRepository.save(shift);

        reportInstanceRepository.findByShift_ShiftId(shift.getShiftId())
                .ifPresent(report -> {
                    report.setClosedAt(endedAt);

                    if (report.getStatus() == null) {
                        report.setStatus(ReportStatus.not_ready);
                    }

                    reportInstanceRepository.save(report);
                });
    }
}
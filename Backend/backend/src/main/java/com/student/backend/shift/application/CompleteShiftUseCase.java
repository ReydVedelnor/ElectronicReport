package com.student.backend.shift.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.report.domain.enums.ReportStatus;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.AttributeValueRepository;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.shift.domain.enums.ShiftStatus;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.shift.domain.repository.ShiftRepository;
import com.student.backend.template.domain.enums.AttributeNodeType;
import com.student.backend.template.domain.model.TemplateAttribute;
import com.student.backend.template.domain.repository.TemplateAttributeRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CompleteShiftUseCase {

    private final ShiftRepository shiftRepository;
    private final ReportInstanceRepository reportInstanceRepository;
    private final TemplateAttributeRepository templateAttributeRepository;
    private final AttributeValueRepository attributeValueRepository;

    @Transactional
    public void complete(UUID shiftId) {

        if (shiftId == null) {
            throw new BadRequestException("shiftId обязателен");
        }

        // 1. найти shift
        Shift shift = shiftRepository.findById(shiftId)
                .orElseThrow(() -> new NotFoundException("Смена не найдена"));

        // 2. проверить статус
        if (shift.getStatus() != ShiftStatus.open) {
            throw new BadRequestException("Смена уже закрыта");
        }

        // 3. найти report
        ReportInstance report = reportInstanceRepository.findByShift_ShiftId(shiftId)
                .orElseThrow(() -> new NotFoundException("Отчет для смены не найден"));

        // 4. загрузить template attributes
        List<TemplateAttribute> templateAttributes =
                templateAttributeRepository.findAllByTemplateIdOrderBySortOrderAsc(
                        report.getTemplate().getTemplateId()
                );

        // 5. загрузить значения
        List<AttributeValue> values =
                attributeValueRepository.findAllByReport_ReportId(report.getReportId());

        // 6. валидация required полей
        for (TemplateAttribute ta : templateAttributes) {

            if (ta.getAttribute().getNodeType() == AttributeNodeType.section) {
                continue;
            }

            if (!Boolean.TRUE.equals(ta.getAttribute().getIsRequired())) {
                continue;
            }

            boolean exists = values.stream()
                    .anyMatch(v -> v.getAttribute().getAttributeId()
                            .equals(ta.getAttributeId())
                            && v.getValueText() != null
                            && !v.getValueText().isBlank());

            if (!exists) {
                throw new BadRequestException(
                        "Не заполнено обязательное поле: " + ta.getAttribute().getName()
                );
            }
        }

        // 7. обновление report
        report.setStatus(ReportStatus.ready);
        report.setClosedAt(OffsetDateTime.now());

        // 8. обновление shift
        shift.setStatus(ShiftStatus.closed);
        shift.setEndedAt(OffsetDateTime.now());

        // save (не обязательно, но можно явно)
        reportInstanceRepository.save(report);
        shiftRepository.save(shift);
    }
}
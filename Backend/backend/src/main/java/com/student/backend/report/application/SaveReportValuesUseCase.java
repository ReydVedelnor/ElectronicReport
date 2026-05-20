package com.student.backend.report.application;

import com.student.backend.common.exception.BadRequestException;
import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.User;
import com.student.backend.identity.domain.repository.UserRepository;
import com.student.backend.report.domain.enums.ReportStatus;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.AttributeValueHistory;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.AttributeValueHistoryRepository;
import com.student.backend.report.domain.repository.AttributeValueRepository;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.report.dto.request.SaveAttributeValueItemRequest;
import com.student.backend.report.dto.request.SaveReportValuesRequest;
import com.student.backend.report.dto.response.SaveReportValuesResponse;
import com.student.backend.report.dto.response.SavedReportValueResponse;
import com.student.backend.template.domain.enums.AttributeNodeType;
import com.student.backend.template.domain.model.Attribute;
import com.student.backend.template.domain.repository.AttributeRepository;
import com.student.backend.template.domain.repository.TemplateAttributeRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SaveReportValuesUseCase {

    private final ReportInstanceRepository reportInstanceRepository;
    private final AttributeRepository attributeRepository;
    private final AttributeValueRepository attributeValueRepository;
    private final AttributeValueHistoryRepository attributeValueHistoryRepository;
    private final TemplateAttributeRepository templateAttributeRepository;
    private final UserRepository userRepository;

    @Transactional
    public SaveReportValuesResponse save(UUID reportId, SaveReportValuesRequest request) {
        validateRequest(reportId, request);

        ReportInstance report = reportInstanceRepository.findById(reportId)
                .orElseThrow(() -> new NotFoundException("Отчет не найден"));

        String effectiveComment = buildEffectiveComment(report, request.getComment());

        User changedByUser = null;
        if (request.getChangedByUserId() != null) {
            changedByUser = userRepository.findById(request.getChangedByUserId())
                    .orElseThrow(() -> new NotFoundException("Пользователь changedByUserId не найден"));
        }

        List<SavedReportValueResponse> savedItems = new ArrayList<>();

        for (SaveAttributeValueItemRequest item : request.getValues()) {
            if (item.getAttributeId() == null) {
                throw new BadRequestException("attributeId обязателен для каждого элемента values");
            }

            Attribute attribute = attributeRepository.findById(item.getAttributeId())
                    .orElseThrow(() -> new NotFoundException("Атрибут не найден: " + item.getAttributeId()));

            boolean existsInTemplate = templateAttributeRepository
                    .findById(new com.student.backend.template.domain.model.TemplateAttribute.TemplateAttributeId(
                            report.getTemplate().getTemplateId(),
                            attribute.getAttributeId()
                    ))
                    .isPresent();

            if (!existsInTemplate) {
                throw new BadRequestException("Атрибут " + attribute.getAttributeId() + " не принадлежит шаблону отчета");
            }

            if (attribute.getNodeType() == AttributeNodeType.section) {
                throw new BadRequestException("Нельзя сохранять значение для section: " + attribute.getName());
            }

            AttributeValue attributeValue = attributeValueRepository
                    .findByReport_ReportIdAndAttribute_AttributeId(reportId, attribute.getAttributeId())
                    .orElse(null);

            String oldValue = null;

            if (attributeValue == null) {
                attributeValue = AttributeValue.builder()
                        .report(report)
                        .attribute(attribute)
                        .valueText(item.getValue())
                        .build();

                attributeValue = attributeValueRepository.save(attributeValue);
            } else {
                oldValue = attributeValue.getValueText();
                attributeValue.setValueText(item.getValue());
                attributeValue = attributeValueRepository.save(attributeValue);
            }

            AttributeValueHistory history = AttributeValueHistory.builder()
                    .attributeValue(attributeValue)
                    .oldValue(oldValue)
                    .newValue(item.getValue())
                    .changedByUser(changedByUser)
                    .comment(effectiveComment)
                    .build();

            attributeValueHistoryRepository.save(history);

            savedItems.add(
                    SavedReportValueResponse.builder()
                            .attributeId(attribute.getAttributeId())
                            .attributeValueId(attributeValue.getAttributeValueId())
                            .value(attributeValue.getValueText())
                            .build()
            );
        }

        return SaveReportValuesResponse.builder()
                .reportId(report.getReportId())
                .savedCount(savedItems.size())
                .savedValues(savedItems)
                .build();
    }

    private void validateRequest(UUID reportId, SaveReportValuesRequest request) {
        if (reportId == null) {
            throw new BadRequestException("reportId обязателен");
        }
        if (request == null) {
            throw new BadRequestException("Тело запроса отсутствует");
        }
        if (request.getValues() == null || request.getValues().isEmpty()) {
            throw new BadRequestException("Список values не должен быть пустым");
        }
    }

    // Pre-made system comment
    private String buildEffectiveComment(ReportInstance report, String originalComment){
        String safeComment = originalComment == null ? "" : originalComment.trim();

        if (report.getStatus() == ReportStatus.ready){
            return "200 Редактирование после закрытия смены. " + safeComment;
        }

        return safeComment;
    }
}
package com.student.backend.report.htmlpdf.service;

import com.student.backend.common.exception.NotFoundException;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.organization.domain.model.DepartmentTemplate;
import com.student.backend.organization.domain.repository.DepartmentRepository;
import com.student.backend.organization.domain.repository.DepartmentScheduleRepository;
import com.student.backend.organization.domain.repository.DepartmentTemplateRepository;
import com.student.backend.report.domain.model.AttributeValue;
import com.student.backend.report.domain.model.ReportInstance;
import com.student.backend.report.domain.repository.AttributeValueRepository;
import com.student.backend.report.domain.repository.ReportInstanceRepository;
import com.student.backend.report.htmlpdf.dto.DailyReportPdfData;
import com.student.backend.report.htmlpdf.dto.DailyReportPdfGroup;
import com.student.backend.report.htmlpdf.dto.DailyReportPdfRow;
import com.student.backend.report.htmlpdf.dto.DailyReportPdfShift;
import com.student.backend.shift.domain.model.Shift;
import com.student.backend.shift.domain.repository.ShiftRepository;
import com.student.backend.template.domain.model.Attribute;
import com.student.backend.template.domain.model.AttributeGroup;
import com.student.backend.template.domain.model.MeasurementUnit;
import com.student.backend.template.domain.model.ReportTemplate;
import com.student.backend.template.domain.model.TemplateAttribute;
import com.student.backend.template.domain.repository.AttributeGroupRepository;
import com.student.backend.template.domain.repository.TemplateAttributeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DailyReportPdfDataBuilder {

    private static final Locale RU_LOCALE = Locale.forLanguageTag("ru-RU");
    private static final ZoneId REPORT_ZONE_ID = ZoneId.systemDefault();

    private static final DateTimeFormatter REPORT_DATE_FORMATTER =
            DateTimeFormatter.ofPattern("d MMMM uuuu 'года'", RU_LOCALE);

    private static final DateTimeFormatter GENERATED_DATE_FORMATTER =
            DateTimeFormatter.ofPattern("dd.MM.uuuu");

    private static final DateTimeFormatter NOTE_DATE_FORMATTER =
            DateTimeFormatter.ofPattern("dd.MM.uuuu");

    private static final DateTimeFormatter TIME_FORMATTER =
            DateTimeFormatter.ofPattern("HH:mm");

    private final DepartmentRepository departmentRepository;
    private final DepartmentTemplateRepository departmentTemplateRepository;
    private final DepartmentScheduleRepository departmentScheduleRepository;
    private final ShiftRepository shiftRepository;
    private final ReportInstanceRepository reportInstanceRepository;
    private final AttributeValueRepository attributeValueRepository;
    private final TemplateAttributeRepository templateAttributeRepository;
    private final AttributeGroupRepository attributeGroupRepository;

    @Transactional(readOnly = true)
    public DailyReportPdfData build(UUID departmentId, LocalDate reportDate) {
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new NotFoundException("Подразделение не найдено"));

        DepartmentTemplate departmentTemplate = departmentTemplateRepository.findFirstByDepartmentId(departmentId)
                .orElseThrow(() -> new NotFoundException("Для подразделения не назначен шаблон рапорта"));

        ReportTemplate template = departmentTemplate.getTemplate();

        if (template == null) {
            throw new NotFoundException("Шаблон рапорта не найден");
        }

        List<TemplateAttribute> templateAttributes =
                templateAttributeRepository.findAllByTemplateIdOrderBySortOrderAsc(template.getTemplateId());

        List<String> notes = new ArrayList<>();

        List<DailyReportPdfShift> shifts = buildShifts(departmentId, reportDate, notes);

        List<UUID> attributeIds = templateAttributes.stream()
                .map(TemplateAttribute::getAttributeId)
                .toList();

        ShiftValuesContext shiftValuesContext = buildShiftValuesContext(shifts, notes);

        MonthlyTotalsContext monthlyTotalsContext = buildMonthlyTotalsContext(
                departmentId,
                reportDate,
                attributeIds
        );

        List<DailyReportPdfGroup> groups = buildGroups(
                templateAttributes,
                shifts,
                shiftValuesContext,
                monthlyTotalsContext
        );

        return new DailyReportPdfData(
                department.getDepartmentId(),
                resolveDepartmentName(department),
                template.getTemplateId(),
                template.getName(),
                reportDate.format(REPORT_DATE_FORMATTER),
                OffsetDateTime.now().format(GENERATED_DATE_FORMATTER),
                shifts,
                groups,
                notes
        );
    }

    private List<DailyReportPdfShift> buildShifts(UUID departmentId, LocalDate reportDate, List<String> notes) {
        List<DepartmentSchedule> schedules =
                departmentScheduleRepository.findAllByDepartment_DepartmentIdOrderBySortOrderAsc(departmentId);

        if (schedules.isEmpty()) {
            notes.add("*Для подразделения не настроены плановые смены в department_schedules");

            return List.of(new DailyReportPdfShift(
                    null,
                    "Смена отсутствует",
                    "",
                    true,
                    reportDate
                            .plusDays(1)
                            .atStartOfDay(REPORT_ZONE_ID)
                            .toOffsetDateTime()
            ));
        }

        List<DepartmentSchedule> orderedSchedules = orderSchedules(schedules);
        Map<UUID, Integer> scheduleDayOffsets = buildScheduleDayOffsets(orderedSchedules);

        OffsetDateTime searchFromInclusive = reportDate
                .atStartOfDay(REPORT_ZONE_ID)
                .toOffsetDateTime();

        OffsetDateTime searchToExclusive = reportDate
                .plusDays(maxDayOffset(scheduleDayOffsets) + 1L)
                .atStartOfDay(REPORT_ZONE_ID)
                .toOffsetDateTime();

        List<Shift> candidateShifts =
                shiftRepository.findAllByDepartment_DepartmentIdAndStartedAtGreaterThanEqualAndStartedAtLessThanOrderByStartedAtAsc(
                        departmentId,
                        searchFromInclusive,
                        searchToExclusive
                );

        List<DailyReportPdfShift> result = new ArrayList<>();
        boolean hasAnyActualShift = false;

        for (DepartmentSchedule schedule : orderedSchedules) {
            int dayOffset = scheduleDayOffsets.getOrDefault(schedule.getScheduleId(), 0);
            LocalDate expectedStartDate = reportDate.plusDays(dayOffset);

            Shift actualShift = findActualShiftForScheduleAndDate(
                    candidateShifts,
                    schedule,
                    expectedStartDate
            );

            if (actualShift != null) {
                hasAnyActualShift = true;
                result.add(mapActualShift(actualShift, schedule, reportDate, dayOffset));
            } else {
                result.add(mapPlannedShift(schedule, reportDate, dayOffset));
            }
        }

        if (!hasAnyActualShift) {
            notes.add("*Нет смены за дату: " + reportDate.format(NOTE_DATE_FORMATTER));
        }

        return result;
    }

    private List<DepartmentSchedule> orderSchedules(List<DepartmentSchedule> schedules) {
        if (schedules == null || schedules.isEmpty()) {
            return List.of();
        }

        return schedules.stream()
                .sorted(Comparator
                        .comparing(this::resolveScheduleSortOrder)
                        .thenComparing(DepartmentSchedule::getStartTime)
                        .thenComparing(schedule -> schedule.getScheduleId().toString())
                )
                .toList();
    }

    private Map<UUID, Integer> buildScheduleDayOffsets(List<DepartmentSchedule> orderedSchedules) {
        Map<UUID, Integer> offsets = new LinkedHashMap<>();

        int currentDayOffset = 0;
        LocalTime previousStartTime = null;

        for (DepartmentSchedule schedule : orderedSchedules) {
            LocalTime currentStartTime = schedule.getStartTime();

            /*
             * Отчётные сутки идут по порядку department_schedules.sort_order.
             * Если при движении по расписанию start_time стал меньше предыдущего start_time,
             * значит следующая смена стартует уже на следующую календарную дату.
             *
             * Пример:
             * 1 смена 07:00–15:30 -> reportDate
             * 2 смена 15:30–00:00 -> reportDate
             * 3 смена 00:00–07:30 -> reportDate.plusDays(1)
             */
            if (previousStartTime != null
                    && currentStartTime != null
                    && currentStartTime.isBefore(previousStartTime)) {
                currentDayOffset++;
            }

            offsets.put(schedule.getScheduleId(), currentDayOffset);
            previousStartTime = currentStartTime;
        }

        return offsets;
    }

    private int maxDayOffset(Map<UUID, Integer> scheduleDayOffsets) {
        if (scheduleDayOffsets == null || scheduleDayOffsets.isEmpty()) {
            return 0;
        }

        return scheduleDayOffsets.values().stream()
                .max(Integer::compareTo)
                .orElse(0);
    }

    private Shift findActualShiftForScheduleAndDate(
            List<Shift> candidateShifts,
            DepartmentSchedule schedule,
            LocalDate expectedStartDate
    ) {
        if (candidateShifts == null || candidateShifts.isEmpty() || schedule == null || expectedStartDate == null) {
            return null;
        }

        return candidateShifts.stream()
                .filter(shift -> shift.getSchedule() != null)
                .filter(shift -> shift.getSchedule().getScheduleId().equals(schedule.getScheduleId()))
                .filter(shift -> shift.getStartedAt() != null)
                .filter(shift -> shift.getStartedAt()
                        .atZoneSameInstant(REPORT_ZONE_ID)
                        .toLocalDate()
                        .equals(expectedStartDate))
                .sorted(Comparator
                        .comparing(Shift::getStartedAt)
                        .thenComparing(shift -> shift.getShiftId().toString())
                )
                .findFirst()
                .orElse(null);
    }

    private DailyReportPdfShift mapActualShift(
            Shift shift,
            DepartmentSchedule schedule,
            LocalDate reportDate,
            int dayOffset
    ) {
        String title = resolveScheduleName(schedule);
        String time = formatScheduleTime(schedule);
        LocalDate scheduleStartDate = reportDate.plusDays(dayOffset);

        return new DailyReportPdfShift(
                shift.getShiftId(),
                title,
                time,
                false,
                resolvePlannedAccumulationEndTime(schedule, scheduleStartDate)
        );
    }

    private DailyReportPdfShift mapPlannedShift(
            DepartmentSchedule schedule,
            LocalDate reportDate,
            int dayOffset
    ) {
        String title = resolveScheduleName(schedule);
        String time = formatScheduleTime(schedule);
        LocalDate scheduleStartDate = reportDate.plusDays(dayOffset);

        return new DailyReportPdfShift(
                null,
                title,
                time,
                true,
                resolvePlannedAccumulationEndTime(schedule, scheduleStartDate)
        );
    }

    private String formatScheduleTime(DepartmentSchedule schedule) {
        if (schedule == null || schedule.getStartTime() == null || schedule.getEndTime() == null) {
            return "";
        }

        return schedule.getStartTime().format(TIME_FORMATTER)
                + "–"
                + schedule.getEndTime().format(TIME_FORMATTER);
    }

    private String resolveScheduleName(DepartmentSchedule schedule) {
        if (schedule == null || schedule.getName() == null || schedule.getName().trim().isEmpty()) {
            return "Смена";
        }

        return schedule.getName().trim();
    }

    private Integer resolveScheduleSortOrder(DepartmentSchedule schedule) {
        if (schedule == null || schedule.getSortOrder() == null) {
            return 0;
        }

        return schedule.getSortOrder();
    }

    private List<DailyReportPdfGroup> buildGroups(
            List<TemplateAttribute> templateAttributes,
            List<DailyReportPdfShift> shifts,
            ShiftValuesContext shiftValuesContext,
            MonthlyTotalsContext monthlyTotalsContext
    ) {
        if (templateAttributes == null || templateAttributes.isEmpty()) {
            return List.of();
        }

        List<UUID> groupIds = templateAttributes.stream()
                .map(TemplateAttribute::getAttribute)
                .map(Attribute::getGroupId)
                .distinct()
                .toList();

        Map<UUID, AttributeGroup> groupsById = attributeGroupRepository.findAllById(groupIds).stream()
                .collect(Collectors.toMap(AttributeGroup::getGroupId, group -> group));

        for (UUID groupId : groupIds) {
            if (!groupsById.containsKey(groupId)) {
                throw new NotFoundException("Группа атрибутов не найдена: " + groupId);
            }
        }

        Map<UUID, GroupAccumulator> accumulators = new LinkedHashMap<>();

        int rowNumber = 1;

        for (TemplateAttribute templateAttribute : templateAttributes) {
            Attribute attribute = templateAttribute.getAttribute();

            AttributeGroup group = groupsById.get(attribute.getGroupId());

            GroupAccumulator accumulator = accumulators.computeIfAbsent(
                    group.getGroupId(),
                    id -> new GroupAccumulator(group, templateAttribute.getSortOrder())
            );

            accumulator.registerSortOrder(templateAttribute.getSortOrder());

            boolean numbered = Boolean.TRUE.equals(templateAttribute.getIsNumbered());
            boolean numeric = isNumericAttribute(attribute);
            String number = numbered ? String.valueOf(rowNumber++) : null;

            DailyReportPdfRow row = new DailyReportPdfRow(
                    attribute.getAttributeId(),
                    number,
                    attribute.getName(),
                    resolveUnit(attribute),
                    resolveDataTypeBaseType(attribute),
                    numbered,
                    isBold(templateAttribute),
                    numeric,
                    buildShiftValues(
                            attribute.getAttributeId(),
                            shifts,
                            shiftValuesContext,
                            monthlyTotalsContext,
                            numeric
                    )
            );

            accumulator.rows.add(row);
        }

        return accumulators.values().stream()
                .sorted(Comparator
                        .comparing(GroupAccumulator::getSortOrder, Comparator.nullsLast(Integer::compareTo))
                        .thenComparing(acc -> normalize(acc.group.getName()))
                        .thenComparing(acc -> acc.group.getGroupId().toString())
                )
                .map(acc -> new DailyReportPdfGroup(
                        acc.group.getGroupId(),
                        acc.group.getName(),
                        acc.sortOrder,
                        acc.rows
                ))
                .toList();
    }

    private ShiftValuesContext buildShiftValuesContext(List<DailyReportPdfShift> shifts, List<String> notes) {
        List<UUID> shiftIds = shifts.stream()
                .map(DailyReportPdfShift::getShiftId)
                .filter(id -> id != null)
                .toList();

        if (shiftIds.isEmpty()) {
            return new ShiftValuesContext(Map.of(), Map.of());
        }

        List<ReportInstance> reportInstances = reportInstanceRepository.findAllByShift_ShiftIdIn(shiftIds);

        Map<UUID, ReportInstance> reportsByShiftId = reportInstances.stream()
                .collect(Collectors.toMap(
                        report -> report.getShift().getShiftId(),
                        report -> report,
                        (first, second) -> first
                ));

        for (DailyReportPdfShift shift : shifts) {
            UUID shiftId = shift.getShiftId();

            if (shiftId != null && !reportsByShiftId.containsKey(shiftId)) {
                notes.add("*Для смены \"" + shift.getTitle() + "\" нет отчета - ошибка системы!");
            }
        }

        List<UUID> reportIds = reportInstances.stream()
                .map(ReportInstance::getReportId)
                .toList();

        if (reportIds.isEmpty()) {
            return new ShiftValuesContext(reportsByShiftId, Map.of());
        }

        List<AttributeValue> attributeValues = attributeValueRepository.findAllByReport_ReportIdIn(reportIds);

        Map<UUID, Map<UUID, String>> valuesByReportIdAndAttributeId = new LinkedHashMap<>();

        for (AttributeValue attributeValue : attributeValues) {
            if (attributeValue.getReport() == null || attributeValue.getAttribute() == null) {
                continue;
            }

            UUID reportId = attributeValue.getReport().getReportId();
            UUID attributeId = attributeValue.getAttribute().getAttributeId();

            valuesByReportIdAndAttributeId
                    .computeIfAbsent(reportId, ignored -> new LinkedHashMap<>())
                    .put(attributeId, normalizeCellValue(attributeValue.getValueText()));
        }

        return new ShiftValuesContext(reportsByShiftId, valuesByReportIdAndAttributeId);
    }

    private MonthlyTotalsContext buildMonthlyTotalsContext(
            UUID departmentId,
            LocalDate reportDate,
            List<UUID> attributeIds
    ) {
        if (attributeIds == null || attributeIds.isEmpty()) {
            return new MonthlyTotalsContext(Map.of());
        }

        LocalDate monthStartDate = reportDate.withDayOfMonth(1);
        LocalDate nextMonthStartDate = monthStartDate.plusMonths(1);

        Map<UUID, Integer> scheduleDayOffsets = buildScheduleDayOffsetsForDepartment(departmentId);
        int maxDayOffset = maxDayOffset(scheduleDayOffsets);

        OffsetDateTime monthSearchStartInclusive = monthStartDate
                .atStartOfDay(REPORT_ZONE_ID)
                .toOffsetDateTime();

        /*
         * Берём запас после конца месяца, чтобы включить смены,
         * которые стартуют уже в следующем календарном месяце,
         * но относятся к последнему отчётному дню предыдущего месяца.
         *
         * Например:
         * отчётный день 31.01
         * 3 смена стартует 01.02 00:00
         * но относится к отчётным суткам 31.01.
         */
        OffsetDateTime monthSearchEndExclusive = nextMonthStartDate
                .plusDays(maxDayOffset + 1L)
                .atStartOfDay(REPORT_ZONE_ID)
                .toOffsetDateTime();

        List<AttributeValue> monthlyValues = attributeValueRepository.findAllForMonthlyPdfTotals(
                departmentId,
                monthSearchStartInclusive,
                monthSearchEndExclusive,
                attributeIds
        );

        // Месячное значение в PDF — это не общий итог месяца.
        // Для каждой колонки смены считается накопительный итог строго по attributeId:
        // суммируются все числовые AttributeValue этого атрибута
        // с начала отчетного месяца до планового конца текущей смены включительно.
        // Отчетная дата смены определяется по порядку department_schedules:
        // например, 3 смена с start_time=00:00 может стартовать на следующий календарный день,
        // но относиться к предыдущим отчетным суткам.
        Map<UUID, List<MonthlyValuePoint>> valuesByAttributeId = new LinkedHashMap<>();

        for (AttributeValue attributeValue : monthlyValues) {
            if (attributeValue.getAttribute() == null
                    || attributeValue.getReport() == null
                    || attributeValue.getReport().getShift() == null) {
                continue;
            }

            UUID attributeId = attributeValue.getAttribute().getAttributeId();

            BigDecimal numericValue = parseDecimalOrNull(attributeValue.getValueText());

            if (numericValue == null) {
                continue;
            }

            Shift valueShift = attributeValue.getReport().getShift();

            LocalDate valueReportDate = resolveReportDateForShift(valueShift, scheduleDayOffsets);

            if (valueReportDate == null
                    || valueReportDate.isBefore(monthStartDate)
                    || !valueReportDate.isBefore(nextMonthStartDate)) {
                continue;
            }

            OffsetDateTime accumulationTime = resolveMonthlyAccumulationTime(valueShift, scheduleDayOffsets);

            if (accumulationTime == null) {
                continue;
            }

            valuesByAttributeId
                    .computeIfAbsent(attributeId, ignored -> new ArrayList<>())
                    .add(new MonthlyValuePoint(accumulationTime, numericValue));
        }

        for (List<MonthlyValuePoint> points : valuesByAttributeId.values()) {
            points.sort(Comparator.comparing(MonthlyValuePoint::getAccumulationTime));
        }

        return new MonthlyTotalsContext(valuesByAttributeId);
    }

    private Map<UUID, Integer> buildScheduleDayOffsetsForDepartment(UUID departmentId) {
        List<DepartmentSchedule> schedules =
                departmentScheduleRepository.findAllByDepartment_DepartmentIdOrderBySortOrderAsc(departmentId);

        return buildScheduleDayOffsets(orderSchedules(schedules));
    }

    private LocalDate resolveReportDateForShift(
            Shift shift,
            Map<UUID, Integer> scheduleDayOffsets
    ) {
        if (shift == null || shift.getStartedAt() == null || shift.getSchedule() == null) {
            return null;
        }

        UUID scheduleId = shift.getSchedule().getScheduleId();
        int dayOffset = scheduleDayOffsets.getOrDefault(scheduleId, 0);

        LocalDate shiftStartDate = shift.getStartedAt()
                .atZoneSameInstant(REPORT_ZONE_ID)
                .toLocalDate();

        return shiftStartDate.minusDays(dayOffset);
    }

    private OffsetDateTime resolveMonthlyAccumulationTime(
            Shift shift,
            Map<UUID, Integer> scheduleDayOffsets
    ) {
        if (shift == null || shift.getStartedAt() == null || shift.getSchedule() == null) {
            return null;
        }

        UUID scheduleId = shift.getSchedule().getScheduleId();
        int dayOffset = scheduleDayOffsets.getOrDefault(scheduleId, 0);

        LocalDate shiftStartDate = shift.getStartedAt()
                .atZoneSameInstant(REPORT_ZONE_ID)
                .toLocalDate();

        LocalDate reportDate = shiftStartDate.minusDays(dayOffset);
        LocalDate scheduleStartDate = reportDate.plusDays(dayOffset);

        return resolvePlannedAccumulationEndTime(shift.getSchedule(), scheduleStartDate);
    }

    private List<String> buildShiftValues(
            UUID attributeId,
            List<DailyReportPdfShift> shifts,
            ShiftValuesContext shiftValuesContext,
            MonthlyTotalsContext monthlyTotalsContext,
            boolean numeric
    ) {
        List<String> values = new ArrayList<>();

        for (DailyReportPdfShift shift : shifts) {
            String shiftValue = resolveShiftValue(attributeId, shift, shiftValuesContext);

            if (numeric) {
                String monthlyValue = resolveMonthlyTotal(attributeId, shift, monthlyTotalsContext);
                values.add(shiftValue + "/" + monthlyValue);
            } else {
                values.add(shiftValue);
            }
        }

        return values;
    }

    private String resolveShiftValue(UUID attributeId, DailyReportPdfShift shift, ShiftValuesContext context) {
        if (shift.getShiftId() == null) {
            return "-";
        }

        ReportInstance reportInstance = context.reportsByShiftId.get(shift.getShiftId());

        if (reportInstance == null) {
            return "-";
        }

        Map<UUID, String> valuesByAttributeId =
                context.valuesByReportIdAndAttributeId.get(reportInstance.getReportId());

        if (valuesByAttributeId == null) {
            return "-";
        }

        String value = valuesByAttributeId.get(attributeId);

        if (value == null || value.isBlank()) {
            return "-";
        }

        return value;
    }

    private String resolveMonthlyTotal(
            UUID attributeId,
            DailyReportPdfShift shift,
            MonthlyTotalsContext context
    ) {
        if (shift == null || shift.getAccumulationEndTime() == null) {
            return "-";
        }

        List<MonthlyValuePoint> points = context.valuesByAttributeId.get(attributeId);

        if (points == null || points.isEmpty()) {
            return "-";
        }

        BigDecimal total = BigDecimal.ZERO;

        for (MonthlyValuePoint point : points) {
            if (!point.getAccumulationTime().isAfter(shift.getAccumulationEndTime())) {
                total = total.add(point.getValue());
            }
        }

        return formatDecimal(total);
    }

    private OffsetDateTime resolvePlannedAccumulationEndTime(DepartmentSchedule schedule, LocalDate scheduleStartDate) {
        if (schedule == null || schedule.getEndTime() == null || scheduleStartDate == null) {
            return null;
        }

        LocalDate endDate = scheduleStartDate;

        if (Boolean.TRUE.equals(schedule.getCrossesMidnight())
                || isEndTimeNotAfterStartTime(schedule)) {
            endDate = scheduleStartDate.plusDays(1);
        }

        return endDate
                .atTime(schedule.getEndTime())
                .atZone(REPORT_ZONE_ID)
                .toOffsetDateTime();
    }

    private boolean isEndTimeNotAfterStartTime(DepartmentSchedule schedule) {
        if (schedule == null || schedule.getStartTime() == null || schedule.getEndTime() == null) {
            return false;
        }

        return !schedule.getEndTime().isAfter(schedule.getStartTime());
    }

    private BigDecimal parseDecimalOrNull(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }

        String normalized = value.trim()
                .replace(" ", "")
                .replace(",", ".");

        try {
            return new BigDecimal(normalized);
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String formatDecimal(BigDecimal value) {
        if (value == null) {
            return "-";
        }

        BigDecimal normalized = value.stripTrailingZeros();

        if (normalized.scale() < 0) {
            normalized = normalized.setScale(0, RoundingMode.UNNECESSARY);
        }

        return normalized.toPlainString();
    }

    private String normalizeCellValue(String value) {
        if (value == null || value.trim().isEmpty()) {
            return "-";
        }

        return value.trim();
    }

    private boolean isBold(TemplateAttribute templateAttribute) {
        return templateAttribute.getDisplayStyle() != null
                && "bold".equalsIgnoreCase(templateAttribute.getDisplayStyle().name());
    }

    private boolean isNumericAttribute(Attribute attribute) {
        String baseType = resolveDataTypeBaseType(attribute);

        if (baseType == null) {
            return false;
        }

        String normalized = baseType.trim().toLowerCase(Locale.ROOT);

        return normalized.equals("numeric")
                || normalized.equals("number")
                || normalized.equals("integer")
                || normalized.equals("decimal")
                || normalized.equals("float")
                || normalized.equals("double");
    }

    private String resolveDataTypeBaseType(Attribute attribute) {
        if (attribute.getDataType() == null) {
            return null;
        }

        return attribute.getDataType().getBaseType();
    }

    private String resolveUnit(Attribute attribute) {
        MeasurementUnit unit = attribute.getUnit();

        if (unit == null) {
            return null;
        }

        if (unit.getShortName() != null && !unit.getShortName().trim().isEmpty()) {
            return unit.getShortName().trim();
        }

        return unit.getName();
    }

    private String resolveDepartmentName(Department department) {
        if (department.getShortName() != null && !department.getShortName().trim().isEmpty()) {
            return department.getShortName().trim();
        }

        return department.getName();
    }

    private String normalize(String value) {
        if (value == null) {
            return "";
        }

        return value.trim().toLowerCase(RU_LOCALE);
    }

    private static class ShiftValuesContext {

        private final Map<UUID, ReportInstance> reportsByShiftId;
        private final Map<UUID, Map<UUID, String>> valuesByReportIdAndAttributeId;

        private ShiftValuesContext(
                Map<UUID, ReportInstance> reportsByShiftId,
                Map<UUID, Map<UUID, String>> valuesByReportIdAndAttributeId
        ) {
            this.reportsByShiftId = reportsByShiftId;
            this.valuesByReportIdAndAttributeId = valuesByReportIdAndAttributeId;
        }
    }

    private static class MonthlyTotalsContext {

        private final Map<UUID, List<MonthlyValuePoint>> valuesByAttributeId;

        private MonthlyTotalsContext(Map<UUID, List<MonthlyValuePoint>> valuesByAttributeId) {
            this.valuesByAttributeId = valuesByAttributeId;
        }
    }

    private static class MonthlyValuePoint {

        private final OffsetDateTime accumulationTime;
        private final BigDecimal value;

        private MonthlyValuePoint(OffsetDateTime accumulationTime, BigDecimal value) {
            this.accumulationTime = accumulationTime;
            this.value = value;
        }

        private OffsetDateTime getAccumulationTime() {
            return accumulationTime;
        }

        private BigDecimal getValue() {
            return value;
        }
    }

    private static class GroupAccumulator {

        private final AttributeGroup group;
        private final List<DailyReportPdfRow> rows = new ArrayList<>();
        private Integer sortOrder;

        private GroupAccumulator(AttributeGroup group, Integer sortOrder) {
            this.group = group;
            this.sortOrder = sortOrder;
        }

        private void registerSortOrder(Integer candidate) {
            if (candidate == null) {
                return;
            }

            if (sortOrder == null || candidate < sortOrder) {
                sortOrder = candidate;
            }
        }

        private Integer getSortOrder() {
            return sortOrder;
        }
    }
}
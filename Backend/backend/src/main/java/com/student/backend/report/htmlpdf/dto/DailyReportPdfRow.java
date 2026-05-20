package com.student.backend.report.htmlpdf.dto;

import java.util.List;
import java.util.UUID;

public class DailyReportPdfRow {

    private final UUID attributeId;
    private final String number;
    private final String name;
    private final String unit;
    private final String dataTypeBaseType;
    private final boolean numbered;
    private final boolean bold;
    private final boolean numeric;
    private final List<String> values;

    public DailyReportPdfRow(
            UUID attributeId,
            String number,
            String name,
            String unit,
            String dataTypeBaseType,
            boolean numbered,
            boolean bold,
            boolean numeric,
            List<String> values
    ) {
        this.attributeId = attributeId;
        this.number = number;
        this.name = name;
        this.unit = unit;
        this.dataTypeBaseType = dataTypeBaseType;
        this.numbered = numbered;
        this.bold = bold;
        this.numeric = numeric;
        this.values = values;
    }

    public UUID getAttributeId() {
        return attributeId;
    }

    public String getNumber() {
        return number;
    }

    public String getName() {
        return name;
    }

    public String getUnit() {
        return unit;
    }

    public String getDataTypeBaseType() {
        return dataTypeBaseType;
    }

    public boolean isNumbered() {
        return numbered;
    }

    public boolean isBold() {
        return bold;
    }

    public boolean isNumeric() {
        return numeric;
    }

    public List<String> getValues() {
        return values;
    }
}
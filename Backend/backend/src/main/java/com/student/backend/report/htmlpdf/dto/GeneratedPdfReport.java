package com.student.backend.report.htmlpdf.dto;

public class GeneratedPdfReport {

    private final String filename;
    private final byte[] content;

    public GeneratedPdfReport(String filename, byte[] content) {
        this.filename = filename;
        this.content = content;
    }

    public String getFilename() {
        return filename;
    }

    public byte[] getContent() {
        return content;
    }
}
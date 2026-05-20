package com.student.backend.report.htmlpdf.service;

import com.openhtmltopdf.pdfboxout.PdfRendererBuilder;
import com.student.backend.common.exception.BadRequestException;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;

@Service
public class HtmlToPdfService {

    private static final String REPORT_BASE_RESOURCE_PATH = "reports/daily/";
    private static final String FONT_RESOURCE_PATH = "reports/fonts/times.ttf";
    private static final String FONT_FAMILY = "Times New Roman";

    public byte[] convert(String html) {
        if (html == null || html.trim().isEmpty()) {
            throw new BadRequestException("HTML для PDF не должен быть пустым");
        }

        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            PdfRendererBuilder builder = new PdfRendererBuilder();

            builder.useFastMode();
            builder.withHtmlContent(html, getBaseUri());
            builder.useFont(resolveFontFile(), FONT_FAMILY);
            builder.toStream(outputStream);
            builder.run();

            return outputStream.toByteArray();
        } catch (Exception ex) {
            throw new RuntimeException("Не удалось сформировать PDF", ex);
        }
    }

    private String getBaseUri() {
        URL baseUrl = getClass().getClassLoader().getResource(REPORT_BASE_RESOURCE_PATH);

        if (baseUrl == null) {
            throw new RuntimeException("Не найдена папка ресурсов PDF-отчета: " + REPORT_BASE_RESOURCE_PATH);
        }

        return baseUrl.toExternalForm();
    }

    private File resolveFontFile() {
        try {
            URL fontUrl = getClass().getClassLoader().getResource(FONT_RESOURCE_PATH);

            if (fontUrl == null) {
                throw new RuntimeException("Не найден файл шрифта: " + FONT_RESOURCE_PATH);
            }

            if ("file".equalsIgnoreCase(fontUrl.getProtocol())) {
                return new File(fontUrl.toURI());
            }

            File tempFontFile = File.createTempFile("daily-report-font-", ".ttf");
            tempFontFile.deleteOnExit();

            try (InputStream inputStream = getClass().getClassLoader().getResourceAsStream(FONT_RESOURCE_PATH)) {
                if (inputStream == null) {
                    throw new RuntimeException("Не удалось прочитать файл шрифта: " + FONT_RESOURCE_PATH);
                }

                Files.copy(inputStream, tempFontFile.toPath(), StandardCopyOption.REPLACE_EXISTING);
            }

            return tempFontFile;
        } catch (Exception ex) {
            throw new RuntimeException("Не удалось подключить шрифт PDF-отчета", ex);
        }
    }
}
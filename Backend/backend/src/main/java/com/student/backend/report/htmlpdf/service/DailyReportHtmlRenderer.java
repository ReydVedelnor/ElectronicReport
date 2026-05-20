package com.student.backend.report.htmlpdf.service;

import com.student.backend.report.htmlpdf.dto.DailyReportPdfData;
import org.springframework.stereotype.Service;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;
import org.thymeleaf.templatemode.TemplateMode;
import org.thymeleaf.templateresolver.ClassLoaderTemplateResolver;

import java.util.Locale;

@Service
public class DailyReportHtmlRenderer {

    private static final Locale RU_LOCALE = Locale.forLanguageTag("ru-RU");

    private final SpringTemplateEngine templateEngine;

    public DailyReportHtmlRenderer() {
        ClassLoaderTemplateResolver templateResolver = new ClassLoaderTemplateResolver();
        templateResolver.setPrefix("reports/daily/");
        templateResolver.setSuffix(".html");
        templateResolver.setTemplateMode(TemplateMode.HTML);
        templateResolver.setCharacterEncoding("UTF-8");
        templateResolver.setCacheable(false);

        this.templateEngine = new SpringTemplateEngine();
        this.templateEngine.setTemplateResolver(templateResolver);
    }

    public String render(DailyReportPdfData data) {
        Context context = new Context(RU_LOCALE);
        context.setVariable("data", data);

        return templateEngine.process("daily-report", context);
    }
}
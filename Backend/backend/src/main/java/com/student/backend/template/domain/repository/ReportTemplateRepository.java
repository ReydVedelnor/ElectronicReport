package com.student.backend.template.domain.repository;

import com.student.backend.template.domain.model.ReportTemplate;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ReportTemplateRepository extends JpaRepository<ReportTemplate, UUID> {
}
package com.student.backend.template.domain.repository;

import com.student.backend.template.domain.model.TemplateAttribute;
import com.student.backend.template.domain.model.TemplateAttribute.TemplateAttributeId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TemplateAttributeRepository extends JpaRepository<TemplateAttribute, TemplateAttributeId> {

    List<TemplateAttribute> findAllByTemplateIdOrderBySortOrderAsc(UUID templateId);
}
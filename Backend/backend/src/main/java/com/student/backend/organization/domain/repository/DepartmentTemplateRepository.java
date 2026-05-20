package com.student.backend.organization.domain.repository;

import com.student.backend.organization.domain.model.DepartmentTemplate;
import com.student.backend.organization.domain.model.DepartmentTemplate.DepartmentTemplateId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface DepartmentTemplateRepository extends JpaRepository<DepartmentTemplate, DepartmentTemplateId> {

    Optional<DepartmentTemplate> findFirstByDepartmentId(UUID departmentId);
}
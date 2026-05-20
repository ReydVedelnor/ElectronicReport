package com.student.backend.organization.domain.repository;

import com.student.backend.organization.domain.model.Department;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DepartmentRepository extends JpaRepository<Department, UUID> {
    List<Department> findAllByParentDepartment_DepartmentIdAndIsActiveTrueOrderByNameAsc(UUID parentDepartmentId);

    List<Department> findAllByParentDepartment_DepartmentIdOrderByNameAsc(UUID parentDepartmentId);
}
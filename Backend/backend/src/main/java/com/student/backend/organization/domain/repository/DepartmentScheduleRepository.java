package com.student.backend.organization.domain.repository;

import com.student.backend.organization.domain.model.DepartmentSchedule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface DepartmentScheduleRepository extends JpaRepository<DepartmentSchedule, UUID> {

    List<DepartmentSchedule> findAllByDepartment_DepartmentIdOrderBySortOrderAsc(UUID departmentId);
}
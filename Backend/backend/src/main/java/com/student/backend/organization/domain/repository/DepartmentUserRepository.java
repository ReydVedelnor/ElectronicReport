package com.student.backend.organization.domain.repository;

import com.student.backend.organization.domain.model.DepartmentUser;
import com.student.backend.organization.domain.model.DepartmentUser.DepartmentUserId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DepartmentUserRepository extends JpaRepository<DepartmentUser, DepartmentUserId> {

    List<DepartmentUser> findAllByUserId(UUID userId);

    // Для редактирования сотрудника
    Optional<DepartmentUser> findFirstByUserId(UUID userId);
}
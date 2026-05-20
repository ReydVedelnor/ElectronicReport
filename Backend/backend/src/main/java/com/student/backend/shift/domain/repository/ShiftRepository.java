package com.student.backend.shift.domain.repository;

import com.student.backend.shift.domain.enums.ShiftStatus;
import com.student.backend.shift.domain.model.Shift;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ShiftRepository extends JpaRepository<Shift, UUID> {

    Optional<Shift> findFirstByDepartment_DepartmentIdAndStartedAtBeforeOrderByStartedAtDesc(
            UUID departmentId,
            OffsetDateTime startedAt
    );

    List<Shift> findAllByDepartment_DepartmentIdAndStartedAtGreaterThanEqualAndStartedAtLessThanOrderByStartedAtAsc(
            UUID departmentId,
            OffsetDateTime fromInclusive,
            OffsetDateTime toExclusive
    );

    Optional<Shift> findFirstByEngineer_UserIdAndStatusOrderByStartedAtDesc(
            UUID userId,
            ShiftStatus status
    );
}
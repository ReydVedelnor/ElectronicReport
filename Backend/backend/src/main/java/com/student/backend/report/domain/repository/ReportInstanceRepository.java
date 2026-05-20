package com.student.backend.report.domain.repository;

import com.student.backend.report.domain.model.ReportInstance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ReportInstanceRepository extends JpaRepository<ReportInstance, UUID> {

    Optional<ReportInstance> findByShift_ShiftId(UUID shiftId);

    List<ReportInstance> findAllByShift_ShiftIdIn(Collection<UUID> shiftIds);
}
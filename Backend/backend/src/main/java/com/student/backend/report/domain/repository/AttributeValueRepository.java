package com.student.backend.report.domain.repository;

import com.student.backend.report.domain.model.AttributeValue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AttributeValueRepository extends JpaRepository<AttributeValue, UUID> {

    Optional<AttributeValue> findByReport_ReportIdAndAttribute_AttributeId(UUID reportId, UUID attributeId);

    List<AttributeValue> findAllByReport_ReportId(UUID reportId);

    List<AttributeValue> findAllByReport_ReportIdIn(Collection<UUID> reportIds);

    // Для daily pdf
    @Query("""
        select av
        from AttributeValue av
        join fetch av.report r
        join fetch r.shift s
        join fetch av.attribute a
        where s.department.departmentId = :departmentId
          and s.startedAt >= :fromInclusive
          and s.startedAt < :toExclusive
          and a.attributeId in :attributeIds
        """)
    List<AttributeValue> findAllForMonthlyPdfTotals(
            @Param("departmentId") UUID departmentId,
            @Param("fromInclusive") OffsetDateTime fromInclusive,
            @Param("toExclusive") OffsetDateTime toExclusive,
            @Param("attributeIds") Collection<UUID> attributeIds
    );
}
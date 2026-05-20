package com.student.backend.report.domain.repository;

import com.student.backend.report.domain.model.AttributeValueHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AttributeValueHistoryRepository extends JpaRepository<AttributeValueHistory, UUID> {
}
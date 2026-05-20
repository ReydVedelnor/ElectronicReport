package com.student.backend.template.domain.repository;

import com.student.backend.template.domain.model.AttributeGroup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AttributeGroupRepository extends JpaRepository<AttributeGroup, UUID> {
}
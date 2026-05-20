package com.student.backend.template.domain.repository;

import com.student.backend.template.domain.model.Attribute;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface AttributeRepository extends JpaRepository<Attribute, UUID> {
}
package com.student.backend.template.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Entity
@Table(name = "data_types")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DataType {

    @Id
    @Column(name = "data_type_id", nullable = false, updatable = false)
    private UUID dataTypeId;

    @Column(name = "name", nullable = false, unique = true, length = 100)
    private String name;

    @Column(name = "base_type", nullable = false, length = 50)
    private String baseType;

    @PrePersist
    public void prePersist() {
        if (dataTypeId == null) {
            dataTypeId = UUID.randomUUID();
        }
    }
}
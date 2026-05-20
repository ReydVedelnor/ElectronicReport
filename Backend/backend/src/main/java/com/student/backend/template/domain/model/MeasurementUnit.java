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
@Table(name = "measurement_units")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MeasurementUnit {

    @Id
    @Column(name = "unit_id", nullable = false, updatable = false)
    private UUID unitId;

    @Column(name = "name", nullable = false, unique = true, length = 100)
    private String name;

    @Column(name = "short_name", nullable = false, unique = true, length = 30)
    private String shortName;

    @PrePersist
    public void prePersist() {
        if (unitId == null) {
            unitId = UUID.randomUUID();
        }
    }
}
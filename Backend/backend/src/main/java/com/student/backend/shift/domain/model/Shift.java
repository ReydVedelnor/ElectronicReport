package com.student.backend.shift.domain.model;

import com.student.backend.identity.domain.model.User;
import com.student.backend.organization.domain.model.Department;
import com.student.backend.organization.domain.model.DepartmentSchedule;
import com.student.backend.shift.domain.enums.ShiftStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;


import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "shifts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Shift {

    @Id
    @Column(name = "shift_id", nullable = false, updatable = false)
    private UUID shiftId;

    @Column(name = "started_at", nullable = false)
    private OffsetDateTime startedAt;

    @Column(name = "ended_at")
    private OffsetDateTime endedAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private ShiftStatus status;

    @ManyToOne(optional = false)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @ManyToOne(optional = false)
    @JoinColumn(name = "schedule_id", nullable = false)
    private DepartmentSchedule schedule;

    @ManyToOne(optional = false)
    @JoinColumn(name = "engineer_user_id", nullable = false)
    private User engineer;

    @PrePersist
    public void prePersist() {
        if (shiftId == null) {
            shiftId = UUID.randomUUID();
        }
    }
}
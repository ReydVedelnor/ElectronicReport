package com.student.backend.organization.domain.model;

import com.student.backend.identity.domain.model.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "department_users")
@IdClass(DepartmentUser.DepartmentUserId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DepartmentUser {

    @Id
    @Column(name = "department_id", nullable = false)
    private UUID departmentId;

    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "department_id", nullable = false, insertable = false, updatable = false)
    private Department department;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false, insertable = false, updatable = false)
    private User user;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class DepartmentUserId implements Serializable {
        private UUID departmentId;
        private UUID userId;
    }
}
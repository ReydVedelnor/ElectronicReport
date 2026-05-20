package com.student.backend.identity.domain.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.util.UUID;

@Entity
@Table(name = "role_modules")
@IdClass(RoleModule.RoleModuleId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class RoleModule {

    @Id
    @Column(name = "role_id", nullable = false)
    private UUID roleId;

    @Id
    @Column(name = "module_id", nullable = false)
    private UUID moduleId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "role_id", nullable = false, insertable = false, updatable = false)
    private Role role;

    @ManyToOne(optional = false)
    @JoinColumn(name = "module_id", nullable = false, insertable = false, updatable = false)
    private Module module;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class RoleModuleId implements Serializable {
        private UUID roleId;
        private UUID moduleId;
    }
}
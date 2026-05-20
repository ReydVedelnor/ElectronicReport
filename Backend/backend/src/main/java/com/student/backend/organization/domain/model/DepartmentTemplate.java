package com.student.backend.organization.domain.model;

import com.student.backend.template.domain.model.ReportTemplate;
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
@Table(name = "department_templates")
@IdClass(DepartmentTemplate.DepartmentTemplateId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class DepartmentTemplate {

    @Id
    @Column(name = "department_id", nullable = false)
    private UUID departmentId;

    @Id
    @Column(name = "template_id", nullable = false)
    private UUID templateId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "department_id", nullable = false, insertable = false, updatable = false)
    private Department department;

    @ManyToOne(optional = false)
    @JoinColumn(name = "template_id", nullable = false, insertable = false, updatable = false)
    private ReportTemplate template;

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class DepartmentTemplateId implements Serializable {
        private UUID departmentId;
        private UUID templateId;
    }
}
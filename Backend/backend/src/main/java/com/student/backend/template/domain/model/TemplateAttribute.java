package com.student.backend.template.domain.model;

import com.student.backend.template.domain.enums.TemplateAttributeDisplayStyle;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

@Entity
@Table(name = "template_attributes")
@IdClass(TemplateAttribute.TemplateAttributeId.class)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TemplateAttribute {

    @Id
    @Column(name = "template_id", nullable = false)
    private UUID templateId;

    @Id
    @Column(name = "attribute_id", nullable = false)
    private UUID attributeId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "template_id", nullable = false, insertable = false, updatable = false)
    private ReportTemplate template;

    @ManyToOne(optional = false)
    @JoinColumn(name = "attribute_id", nullable = false, insertable = false, updatable = false)
    private Attribute attribute;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;

    @Column(name = "is_numbered", nullable = false)
    private Boolean isNumbered;

    @Enumerated(EnumType.STRING)
    @Column(name = "display_style", nullable = false, length = 20)
    private TemplateAttributeDisplayStyle displayStyle;

    @Column(name = "added_at", nullable = false)
    private OffsetDateTime addedAt;

    @PrePersist
    public void prePersist() {
        if (sortOrder == null) {
            sortOrder = 0;
        }
        if (isNumbered == null) {
            isNumbered = false;
        }
        if (displayStyle == null) {
            displayStyle = TemplateAttributeDisplayStyle.normal;
        }
        if (addedAt == null) {
            addedAt = OffsetDateTime.now();
        }
    }

    @Getter
    @Setter
    @NoArgsConstructor
    @AllArgsConstructor
    @EqualsAndHashCode
    public static class TemplateAttributeId implements Serializable {
        private UUID templateId;
        private UUID attributeId;
    }
}
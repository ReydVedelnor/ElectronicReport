package com.student.backend.report.domain.model;

import com.student.backend.identity.domain.model.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
@Table(name = "attribute_value_history")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttributeValueHistory {

    @Id
    @Column(name = "history_id", nullable = false, updatable = false)
    private UUID historyId;

    @ManyToOne(optional = false)
    @JoinColumn(name = "attribute_value_id", nullable = false)
    private AttributeValue attributeValue;

    @Column(name = "old_value")
    private String oldValue;

    @Column(name = "new_value")
    private String newValue;

    @Column(name = "changed_at", nullable = false)
    private OffsetDateTime changedAt;

    @ManyToOne
    @JoinColumn(name = "changed_by_user_id")
    private User changedByUser;

    @Column(name = "comment")
    private String comment;

    @PrePersist
    public void prePersist() {
        if (historyId == null) {
            historyId = UUID.randomUUID();
        }
        if (changedAt == null) {
            changedAt = OffsetDateTime.now();
        }
    }
}
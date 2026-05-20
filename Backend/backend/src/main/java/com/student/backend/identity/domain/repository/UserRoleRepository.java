package com.student.backend.identity.domain.repository;

import com.student.backend.identity.domain.model.UserRole;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRoleRepository extends JpaRepository<UserRole, UserRole.UserRoleId> {

    Optional<UserRole> findFirstByUser_UserId(UUID userId);

    @Query("""
            select count(distinct ur.userId)
            from UserRole ur
            join ur.user u
            where ur.roleId = :roleId
              and u.isActive = true
            """)
    long countActiveParticipantsByRoleId(@Param("roleId") UUID roleId);

    @Query("""
            select ur.roleId as roleId,
                   count(distinct ur.userId) as participantsCount
            from UserRole ur
            join ur.user u
            where ur.roleId in :roleIds
              and u.isActive = true
            group by ur.roleId
            """)
    List<RoleParticipantsCountProjection> countActiveParticipantsByRoleIds(@Param("roleIds") Collection<UUID> roleIds);

    interface RoleParticipantsCountProjection {

        UUID getRoleId();

        Long getParticipantsCount();
    }
}
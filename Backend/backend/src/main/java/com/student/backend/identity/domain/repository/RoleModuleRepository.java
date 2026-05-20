package com.student.backend.identity.domain.repository;

import com.student.backend.identity.domain.model.RoleModule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RoleModuleRepository extends JpaRepository<RoleModule, RoleModule.RoleModuleId> {

    List<RoleModule> findAllByRoleId(UUID roleId);

}
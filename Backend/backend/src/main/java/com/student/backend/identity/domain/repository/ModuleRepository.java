package com.student.backend.identity.domain.repository;

import com.student.backend.identity.domain.model.Module;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface ModuleRepository extends JpaRepository<Module, UUID> {

    // Для GET /api/roles/{roleId}
    List<Module> findAllByIsActiveTrueOrderByDisplayNameAscSlugAsc();

    // Для POST /api/roles/create
    List<Module> findAllByModuleIdInAndIsActiveTrue(Collection<UUID> moduleIds);
}
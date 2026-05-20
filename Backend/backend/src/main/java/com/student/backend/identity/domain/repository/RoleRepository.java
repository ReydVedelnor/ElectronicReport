package com.student.backend.identity.domain.repository;

import com.student.backend.identity.domain.model.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface RoleRepository extends JpaRepository<Role, UUID>, JpaSpecificationExecutor<Role> {

    List<Role> findAllByIsActiveTrueOrderByNameAsc();

    Optional<Role> findByRoleIdAndIsActiveTrue(UUID roleId);

    // Создание. Проверяем имя на уникальность
    boolean existsByNameIgnoreCase(String name);

    // Редактирвание. Есть ли роль с именем name, кроме роли, которую мы сейчас редактируем?
    boolean existsByNameIgnoreCaseAndRoleIdNot(String name, UUID roleId);
}
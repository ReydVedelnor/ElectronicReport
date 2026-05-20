package com.student.backend.identity.domain.repository;

import com.student.backend.identity.domain.model.Credential;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface CredentialRepository extends JpaRepository<Credential, UUID> {
    // Для входа в систему
    Optional<Credential> findByLogin(String login);

    // Для создания пользователя
    boolean existsByLogin(String login);
}
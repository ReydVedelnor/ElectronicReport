package com.student.backend.identity.application;

import com.student.backend.common.exception.NotFoundException;
import com.student.backend.identity.domain.model.Credential;
import com.student.backend.identity.domain.repository.CredentialRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CredentialAuditService {

    private final CredentialRepository credentialRepository;

    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void increaseFailedLoginAttempts(UUID userId) {
        Credential credential = credentialRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Учетные данные не найдены"));

        int currentAttempts = credential.getFailedLoginAttempts() == null
                ? 0
                : credential.getFailedLoginAttempts();

        credential.setFailedLoginAttempts(currentAttempts + 1);
        credentialRepository.save(credential);
    }

    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void markSuccessfulLogin(UUID userId) {
        Credential credential = credentialRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Учетные данные не найдены"));

        credential.setLastLoginAt(OffsetDateTime.now());
        credential.setFailedLoginAttempts(0);
        credentialRepository.save(credential);
    }
}
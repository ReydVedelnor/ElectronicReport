package com.student.backend.identity.api;

import com.student.backend.identity.application.LoginUseCase;
import com.student.backend.identity.dto.request.LoginRequest;
import com.student.backend.identity.dto.response.LoginResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final LoginUseCase loginUseCase;

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        return loginUseCase.login(request);
    }
}
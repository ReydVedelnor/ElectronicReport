package com.student.backend.identity.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
@AllArgsConstructor
public class LoginModuleResponse {

    private String slug;
    private String displayName;
}
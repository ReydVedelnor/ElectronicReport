package com.student.backend.identity.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.util.List;

@Getter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RoleListResponse {

    private List<RoleListItemResponse> items;

    private int page;
    private int size;

    private long totalElements;
    private int totalPages;
    private boolean hasNext;
}
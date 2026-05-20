package com.student.backend.employee.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EmployeeListResponse {

    private List<EmployeeListItemResponse> items;

    private int page;
    private int size;

    private long totalElements;
    private int totalPages;
    private boolean hasNext;
}
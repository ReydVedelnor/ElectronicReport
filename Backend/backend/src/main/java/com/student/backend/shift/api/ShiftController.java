package com.student.backend.shift.api;

import com.student.backend.shift.application.CompleteShiftUseCase;
import com.student.backend.shift.application.GetCurrentWorkspaceUseCase;
import com.student.backend.shift.application.GetShiftStartContextUseCase;
import com.student.backend.shift.application.OpenShiftUseCase;
import com.student.backend.shift.dto.request.OpenShiftRequest;
import com.student.backend.shift.dto.response.OpenShiftResponse;
import com.student.backend.shift.dto.response.ShiftStartContextResponse;
import com.student.backend.shift.dto.response.WorkspaceCurrentResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/shifts")
@RequiredArgsConstructor
public class ShiftController {

    private final OpenShiftUseCase openShiftUseCase;
    private final CompleteShiftUseCase completeShiftUseCase;
    private final GetShiftStartContextUseCase getShiftStartContextUseCase;
    private final GetCurrentWorkspaceUseCase getCurrentWorkspaceUseCase;

    @PostMapping
    public OpenShiftResponse openShift(@RequestBody OpenShiftRequest request) {
        return openShiftUseCase.open(request);
    }

    @PostMapping("/{shiftId}/complete")
    public void complete(@PathVariable UUID shiftId) {
        completeShiftUseCase.complete(shiftId);
    }

    // Для окна начала смены получаем данные о подразделении и времени смены
    @GetMapping("/start-context")
    public ShiftStartContextResponse getStartContext(@RequestParam UUID userId) {
        return getShiftStartContextUseCase.get(userId);
    }

    //
    @GetMapping("/workspace/current")
    public WorkspaceCurrentResponse getCurrentWorkspace(@RequestParam UUID userId) {
        return getCurrentWorkspaceUseCase.execute(userId);
    }

}
package com.pqdag.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Map;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AllocationResponse {
    private String status;              // "success", "error", "running"
    private String message;
    private AllocationStatistics statistics;
    private List<MachineAllocation> distribution;
    private String affectationFile;     // Path to affectation file
}

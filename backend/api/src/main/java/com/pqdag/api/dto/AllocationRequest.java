package com.pqdag.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AllocationRequest {
    private String datasetName;
    private Integer numMachines;
    private Boolean cleanAfter;
}

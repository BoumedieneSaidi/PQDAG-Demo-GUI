package com.pqdag.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MachineAllocation {
    private Integer machineId;
    private Integer fragmentCount;
    private String workerIp;
}

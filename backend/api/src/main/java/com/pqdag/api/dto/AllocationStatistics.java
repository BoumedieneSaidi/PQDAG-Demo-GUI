package com.pqdag.api.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AllocationStatistics {
    private Integer totalFragments;
    private Integer totalEdges;
    private Double executionTime;       // in seconds
    private String dbStatFile;
    private String graphFile;
}

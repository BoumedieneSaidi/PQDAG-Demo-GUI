package com.pqdag.model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FragmentationResult {
    private boolean success;
    private String message;
    private int fragmentCount;
    private long totalTriples;
    private double executionTimeSeconds;
    private long throughput; // triples per second
    private String dockerOutput;
    
    // Phase timings
    private Double encodingTime;
    private Double dictionariesTime;
    private Double sortingTime;
    private Double fragmentationTime;
    private Double reencodingTime;
}

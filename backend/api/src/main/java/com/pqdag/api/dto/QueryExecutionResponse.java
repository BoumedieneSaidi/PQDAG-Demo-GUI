package com.pqdag.api.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;

@Data
@Builder
public class QueryExecutionResponse {
    private String status;
    private String message;
    private String queryFile;
    private Long executionTimeMs;
    private Integer resultCount;
    private String output;
    private List<String> results;
}

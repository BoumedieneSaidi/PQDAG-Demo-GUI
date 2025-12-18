package com.pqdag.api.dto;

import lombok.Data;

@Data
public class QueryExecutionRequest {
    private String dataset;
    private String queryFile;
    private Integer planNumber;
    private String masterIp;
}

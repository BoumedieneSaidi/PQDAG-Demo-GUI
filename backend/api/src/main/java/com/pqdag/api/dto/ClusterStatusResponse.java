package com.pqdag.api.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class ClusterStatusResponse {
    private String status;
    private String message;
    private String output;
}

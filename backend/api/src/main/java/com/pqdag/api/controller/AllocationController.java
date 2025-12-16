package com.pqdag.api.controller;

import com.pqdag.api.dto.AllocationRequest;
import com.pqdag.api.dto.AllocationResponse;
import com.pqdag.api.service.AllocationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/allocation")
@RequiredArgsConstructor
public class AllocationController {

    private final AllocationService allocationService;

    /**
     * Start the allocation process (steps 1-3: statistics, graph, METIS)
     * Does NOT distribute to cluster
     */
    @PostMapping("/start")
    public ResponseEntity<AllocationResponse> startAllocation(@RequestBody AllocationRequest request) {
        log.info("Starting allocation for dataset: {}, machines: {}", 
                request.getDatasetName(), request.getNumMachines());
        
        try {
            AllocationResponse response = allocationService.runAllocation(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Allocation failed", e);
            return ResponseEntity.internalServerError()
                    .body(AllocationResponse.builder()
                            .status("error")
                            .message("Allocation failed: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Distribute fragments to cluster (step 4)
     * Requires allocation to be completed first
     */
    @PostMapping("/distribute")
    public ResponseEntity<AllocationResponse> distributeFragments(@RequestBody AllocationRequest request) {
        log.info("Starting distribution for dataset: {}", request.getDatasetName());
        
        try {
            AllocationResponse response = allocationService.distributeFragments(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Distribution failed", e);
            return ResponseEntity.internalServerError()
                    .body(AllocationResponse.builder()
                            .status("error")
                            .message("Distribution failed: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Get allocation results for a dataset
     */
    @GetMapping("/results/{datasetName}")
    public ResponseEntity<AllocationResponse> getAllocationResults(@PathVariable String datasetName) {
        log.info("Getting allocation results for dataset: {}", datasetName);
        
        try {
            AllocationResponse response = allocationService.getResults(datasetName);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Failed to get allocation results", e);
            return ResponseEntity.internalServerError()
                    .body(AllocationResponse.builder()
                            .status("error")
                            .message("Failed to get results: " + e.getMessage())
                            .build());
        }
    }
}

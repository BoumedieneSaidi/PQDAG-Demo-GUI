package com.pqdag.api.controller;

import com.pqdag.api.dto.*;
import com.pqdag.api.service.QueryService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/query")
@RequiredArgsConstructor
public class QueryController {

    private final QueryService queryService;

    /**
     * Get list of available datasets
     */
    @GetMapping("/datasets")
    public ResponseEntity<List<String>> getDatasets() {
        try {
            List<String> datasets = queryService.getDatasets();
            return ResponseEntity.ok(datasets);
        } catch (Exception e) {
            log.error("Error getting datasets", e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get list of query files for a dataset
     */
    @GetMapping("/files/{dataset}")
    public ResponseEntity<List<String>> getQueryFiles(@PathVariable String dataset) {
        try {
            List<String> queryFiles = queryService.getQueryFiles(dataset);
            return ResponseEntity.ok(queryFiles);
        } catch (Exception e) {
            log.error("Error getting query files for dataset: {}", dataset, e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get query content from client machine
     */
    @GetMapping("/content/{dataset}/{queryFile}")
    public ResponseEntity<Map<String, String>> getQueryContent(
            @PathVariable String dataset,
            @PathVariable String queryFile) {
        try {
            String content = queryService.getQueryContent(dataset, queryFile);
            if (content != null) {
                return ResponseEntity.ok(Map.of("content", content));
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            log.error("Error getting query content for {}/{}", dataset, queryFile, e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Start PQDAG cluster
     */
    @PostMapping("/start-cluster")
    public ResponseEntity<ClusterStatusResponse> startCluster() {
        try {
            ClusterStatusResponse response = queryService.startCluster();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error starting cluster", e);
            return ResponseEntity.ok(ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while starting cluster: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Stop PQDAG cluster
     */
    @PostMapping("/stop-cluster")
    public ResponseEntity<ClusterStatusResponse> stopCluster() {
        try {
            ClusterStatusResponse response = queryService.stopCluster();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error stopping cluster", e);
            return ResponseEntity.ok(ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while stopping cluster: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Restart PQDAG cluster
     */
    @PostMapping("/restart-cluster")
    public ResponseEntity<ClusterStatusResponse> restartCluster() {
        try {
            ClusterStatusResponse response = queryService.restartCluster();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error restarting cluster", e);
            return ResponseEntity.ok(ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while restarting cluster: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Clear all Java processes on cluster (master, workers, client)
     */
    @PostMapping("/clear-java-processes")
    public ResponseEntity<ClusterStatusResponse> clearJavaProcesses() {
        try {
            ClusterStatusResponse response = queryService.clearJavaProcesses();
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error clearing Java processes", e);
            return ResponseEntity.ok(ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while clearing Java processes: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Execute a SPARQL query
     */
    @PostMapping("/execute")
    public ResponseEntity<QueryExecutionResponse> executeQuery(@RequestBody QueryExecutionRequest request) {
        try {
            QueryExecutionResponse response = queryService.executeQuery(request);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error executing query", e);
            return ResponseEntity.ok(QueryExecutionResponse.builder()
                    .status("error")
                    .message("Exception while executing query: " + e.getMessage())
                    .build());
        }
    }

    /**
     * Get list of available PQDAG datasets from pqdag_data directory
     */
    @GetMapping("/pqdag-datasets")
    public ResponseEntity<List<String>> getPqdagDatasets() {
        try {
            List<String> datasets = queryService.getPqdagDatasets();
            return ResponseEntity.ok(datasets);
        } catch (Exception e) {
            log.error("Error getting PQDAG datasets", e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Get current configured dataset
     */
    @GetMapping("/current-dataset")
    public ResponseEntity<Map<String, String>> getCurrentDataset() {
        try {
            String dataset = queryService.getCurrentDataset();
            return ResponseEntity.ok(Map.of("dataset", dataset != null ? dataset : ""));
        } catch (Exception e) {
            log.error("Error getting current dataset", e);
            return ResponseEntity.internalServerError().build();
        }
    }

    /**
     * Set dataset in config.properties
     */
    @PostMapping("/set-dataset/{dataset}")
    public ResponseEntity<ClusterStatusResponse> setDataset(@PathVariable String dataset) {
        try {
            ClusterStatusResponse response = queryService.setDataset(dataset);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            log.error("Error setting dataset", e);
            return ResponseEntity.ok(ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while setting dataset: " + e.getMessage())
                    .build());
        }
    }
}

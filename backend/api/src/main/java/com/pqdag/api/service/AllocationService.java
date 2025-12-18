package com.pqdag.api.service;

import com.pqdag.api.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;
import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class AllocationService {

    @Value("${workspace.root:/home/boumi/Documents/PQDAG GUI}")
    private String workspaceRoot;

    @Value("${docker.image:pqdag-allocation:latest}")
    private String dockerImage;

    /**
     * Run allocation (steps 1-3): statistics, graph generation, METIS
     */
    public AllocationResponse runAllocation(AllocationRequest request) throws Exception {
        Instant start = Instant.now();
        String datasetName = request.getDatasetName();
        
        log.info("Starting allocation for dataset: {}", datasetName);

        // Step 0: Generate config_runtime.yaml
        generateConfig(datasetName);

        // Step 1: Run stat_MPI.py (with Docker)
        runStatistics(datasetName);

        // Step 2: Run generate_fragments_graph.py
        runGraphGeneration();

        // Step 3: Run weighted_metis.py
        runMetisAllocation(request.getNumMachines());

        // Parse results
        AllocationStatistics stats = parseAllocationResults(datasetName);
        List<MachineAllocation> distribution = parseDistribution();
        
        Duration duration = Duration.between(start, Instant.now());
        stats.setExecutionTime(duration.toMillis() / 1000.0);

        return AllocationResponse.builder()
                .status("success")
                .message("Allocation completed successfully")
                .statistics(stats)
                .distribution(distribution)
                .affectationFile(workspaceRoot + "/storage/allocation_results/affectation_weighted_metis.txt")
                .build();
    }

    /**
     * Distribute fragments to cluster (step 4)
     */
    public AllocationResponse distributeFragments(AllocationRequest request) throws Exception {
        String datasetName = request.getDatasetName();
        
        log.info("Starting distribution for dataset: {}", datasetName);

        // Ensure config is generated
        generateConfig(datasetName);

        // Run distribute_fragments.py using docker exec
        ProcessBuilder pb = new ProcessBuilder(
            "docker", "exec", "pqdag-allocation",
            "python3",
            "/app/allocation/distribute_fragments.py",
            "--config_file",
            "/app/allocation/config_runtime.yaml"
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("Distribution failed: " + output);
        }
        
        log.info("Distribution completed successfully");
        
        // Clean up if requested
        if (Boolean.TRUE.equals(request.getCleanAfter())) {
            cleanupAfterDistribution(datasetName);
        }

        return AllocationResponse.builder()
                .status("success")
                .message("Distribution completed successfully")
                .build();
    }

    /**
     * Clean up temporary files after successful distribution
     */
    private void cleanupAfterDistribution(String datasetName) throws Exception {
        log.info("Cleaning up temporary files after distribution for dataset: {}", datasetName);
        
        try {
            // 1. Clean outputdata directory (fragments)
            Path outputDataPath = Paths.get(workspaceRoot, "storage", "outputdata");
            if (Files.exists(outputDataPath)) {
                Files.walk(outputDataPath)
                    .sorted(Comparator.reverseOrder())
                    .filter(path -> !path.equals(outputDataPath)) // Keep the directory itself
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                            log.debug("Deleted: {}", path);
                        } catch (IOException e) {
                            log.warn("Failed to delete: {}", path, e);
                        }
                    });
                log.info("✓ Cleaned outputdata directory");
            }
            
            // 2. Clean allocation_results directory
            Path allocationResultsPath = Paths.get(workspaceRoot, "storage", "allocation_results");
            if (Files.exists(allocationResultsPath)) {
                Files.walk(allocationResultsPath)
                    .sorted(Comparator.reverseOrder())
                    .filter(path -> !path.equals(allocationResultsPath)) // Keep the directory itself
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                            log.debug("Deleted: {}", path);
                        } catch (IOException e) {
                            log.warn("Failed to delete: {}", path, e);
                        }
                    });
                log.info("✓ Cleaned allocation_results directory");
            }
            
            // 3. Clean allocation_temp directory
            Path allocationTempPath = Paths.get(workspaceRoot, "storage", "allocation_temp");
            if (Files.exists(allocationTempPath)) {
                Files.walk(allocationTempPath)
                    .sorted(Comparator.reverseOrder())
                    .filter(path -> !path.equals(allocationTempPath)) // Keep the directory itself
                    .forEach(path -> {
                        try {
                            Files.delete(path);
                            log.debug("Deleted: {}", path);
                        } catch (IOException e) {
                            log.warn("Failed to delete: {}", path, e);
                        }
                    });
                log.info("✓ Cleaned allocation_temp directory");
            }
            
            log.info("✓ Cleanup completed successfully");
            
        } catch (Exception e) {
            log.error("Error during cleanup", e);
            // Don't throw - cleanup failure shouldn't fail the whole operation
        }
    }

    /**
     * Get allocation results for a dataset
     */
    public AllocationResponse getResults(String datasetName) throws Exception {
        AllocationStatistics stats = parseAllocationResults(datasetName);
        List<MachineAllocation> distribution = parseDistribution();

        return AllocationResponse.builder()
                .status("success")
                .statistics(stats)
                .distribution(distribution)
                .affectationFile(workspaceRoot + "/storage/allocation_results/affectation_weighted_metis.txt")
                .build();
    }

    // ========================================================================
    // Private helper methods
    // ========================================================================

    private void generateConfig(String datasetName) throws Exception {
        log.info("Generating config_runtime.yaml for dataset: {}", datasetName);
        
        ProcessBuilder pb = new ProcessBuilder(
            "docker", "exec", "pqdag-allocation",
            "python3",
            "/app/allocation/generate_config.py",
            datasetName,
            "/app"
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("Config generation failed: " + output);
        }
        
        log.info("Config generated successfully");
    }

    private void runStatistics(String datasetName) throws Exception {
        log.info("Step 1: Running MPI statistics calculation");

        // Use existing pqdag-allocation container
        ProcessBuilder pb = new ProcessBuilder(
            "docker", "exec", "pqdag-allocation",
            "bash", "-c",
            "cd /app/allocation && mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db"
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("Statistics calculation failed: " + output);
        }
        
        log.info("Statistics calculation completed");
    }

    private void runGraphGeneration() throws Exception {
        log.info("Step 2: Running graph generation");

        ProcessBuilder pb = new ProcessBuilder(
            "docker", "exec", "pqdag-allocation",
            "bash", "-c",
            "cd /app/allocation && python3 generate_fragments_graph.py /app/storage/allocation_results/db.stat /app/storage/allocation_results/fragments_graph.quad"
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("Graph generation failed: " + output);
        }
        
        log.info("Graph generation completed");
    }

    private void runMetisAllocation(Integer numMachines) throws Exception {
        log.info("Step 3: Running METIS allocation for {} machines", numMachines);

        ProcessBuilder pb = new ProcessBuilder(
            "docker", "exec", "pqdag-allocation",
            "bash", "-c",
            String.format("cd /app/allocation && python3 allocation_approaches/weighted_metis.py /app/storage/allocation_results/fragments_graph.quad /app/storage/allocation_results/affectation_weighted_metis.txt %d", numMachines)
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0) {
            throw new RuntimeException("METIS allocation failed: " + output);
        }
        
        log.info("METIS allocation completed");
    }

    private AllocationStatistics parseAllocationResults(String datasetName) throws Exception {
        Path dbStatPath = Paths.get(workspaceRoot, "storage", "allocation_results", "db.stat");
        Path graphPath = Paths.get(workspaceRoot, "storage", "allocation_results", "fragments_graph.quad");

        int totalFragments = 0;
        int totalEdges = 0;

        // Count fragments from db.stat
        if (Files.exists(dbStatPath)) {
            totalFragments = (int) Files.lines(dbStatPath).count();
        }

        // Count edges from fragments_graph.quad
        if (Files.exists(graphPath)) {
            totalEdges = (int) Files.lines(graphPath).count();
        }

        return AllocationStatistics.builder()
                .totalFragments(totalFragments)
                .totalEdges(totalEdges)
                .dbStatFile(dbStatPath.toString())
                .graphFile(graphPath.toString())
                .build();
    }

    private List<MachineAllocation> parseDistribution() throws Exception {
        Path affectationPath = Paths.get(workspaceRoot, "storage", "allocation_results", "affectation_weighted_metis.txt");
        
        if (!Files.exists(affectationPath)) {
            return new ArrayList<>();
        }

        // Count fragments per machine
        Map<Integer, Integer> machineFragments = new HashMap<>();
        
        List<String> lines = Files.readAllLines(affectationPath);
        for (String line : lines) {
            String[] parts = line.trim().split("\\s+");
            if (parts.length >= 2) {
                int machineId = Integer.parseInt(parts[1]);
                machineFragments.put(machineId, machineFragments.getOrDefault(machineId, 0) + 1);
            }
        }

        // Read worker IPs
        Map<Integer, String> workerIps = readWorkerIps();

        // Build result
        List<MachineAllocation> result = new ArrayList<>();
        for (Map.Entry<Integer, Integer> entry : machineFragments.entrySet()) {
            result.add(MachineAllocation.builder()
                    .machineId(entry.getKey())
                    .fragmentCount(entry.getValue())
                    .workerIp(workerIps.getOrDefault(entry.getKey(), "unknown"))
                    .build());
        }

        result.sort(Comparator.comparing(MachineAllocation::getMachineId));
        return result;
    }

    private Map<Integer, String> readWorkerIps() throws Exception {
        Path workersPath = Paths.get(workspaceRoot, "backend", "allocation", "workers");
        Map<Integer, String> workerIps = new HashMap<>();
        
        if (Files.exists(workersPath)) {
            List<String> lines = Files.readAllLines(workersPath);
            for (int i = 0; i < lines.size(); i++) {
                workerIps.put(i + 1, lines.get(i).trim());
            }
        }
        
        return workerIps;
    }

    private String readProcessOutput(Process process) throws IOException {
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
                log.info(line);  // Log each line in real-time
            }
        }
        return output.toString();
    }
}

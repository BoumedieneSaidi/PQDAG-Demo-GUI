package com.pqdag.api.service;

import com.pqdag.api.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Service
public class QueryService {

    @Value("${workspace.root:/app}")
    private String workspaceRoot;

    @Value("${client.jar.path:/home/ubuntu/client.jar}")
    private String clientJarPath;

    @Value("${client.queries.path:/home/ubuntu/queries}")
    private String clientQueriesPath;

    @Value("${client.scripts.path:/home/ubuntu/mounted_vol/pqdag-gui/storage/scripts}")
    private String clientScriptsPath;
    
    @Value("${pqdag.installation.path:/home/ubuntu/pqdag}")
    private String pqdagInstallationPath;

    @Value("${pqdag.data.path:/home/ubuntu/mounted_vol/pqdag_data}")
    private String pqdagDataPath;

    @Value("${client.machine.ip:192.168.165.191}")
    private String clientMachineIp;

    /**
     * Get list of available datasets
     */
    public List<String> getDatasets() {
        Path queriesPath = Paths.get(workspaceRoot, "storage", "queries");
        try {
            if (Files.exists(queriesPath)) {
                return Files.list(queriesPath)
                        .filter(Files::isDirectory)
                        .map(path -> path.getFileName().toString())
                        .sorted()
                        .collect(Collectors.toList());
            }
        } catch (IOException e) {
            log.error("Error listing datasets", e);
        }
        return Collections.emptyList();
    }

    /**
     * Get list of query files for a dataset
     */
    public List<String> getQueryFiles(String dataset) {
        Path datasetPath = Paths.get(workspaceRoot, "storage", "queries", dataset);
        try {
            if (Files.exists(datasetPath)) {
                return Files.list(datasetPath)
                        .filter(Files::isRegularFile)
                        .filter(path -> path.getFileName().toString().endsWith(".in"))
                        .map(path -> path.getFileName().toString())
                        .sorted()
                        .collect(Collectors.toList());
            }
        } catch (IOException e) {
            log.error("Error listing query files for dataset: {}", dataset, e);
        }
        return Collections.emptyList();
    }

    /**
     * Get query content from client machine
     */
    public String getQueryContent(String dataset, String queryFile) {
        try {
            // First ensure SSH keys are copied
            ProcessBuilder copyPb = new ProcessBuilder(
                "sh", "-c",
                "cp -r /root/.ssh /tmp/.ssh 2>/dev/null || true && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag"
            );
            copyPb.start().waitFor();

            // Read query file from client machine
            String queryFilePath = clientQueriesPath + "/" + dataset + "/" + queryFile;
            
            ProcessBuilder pb = new ProcessBuilder(
                "ssh",
                "-i", "/tmp/.ssh/pqdag",
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "LogLevel=ERROR",
                "ubuntu@" + clientMachineIp,
                "cat " + queryFilePath
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();
            String content = readProcessOutput(process);
            int exitCode = process.waitFor();
            
            if (exitCode == 0) {
                // Filter out SSH warnings
                return Arrays.stream(content.split("\n"))
                        .filter(line -> !line.startsWith("Warning:"))
                        .collect(Collectors.joining("\n"));
            }
        } catch (Exception e) {
            log.error("Error reading query content for {}/{}", dataset, queryFile, e);
        }
        return null;
    }

    /**
     * Start PQDAG cluster
     */
    public ClusterStatusResponse startCluster() throws Exception {
        log.info("Starting PQDAG cluster - VERSION 12:13");

        // First ensure SSH keys are copied to writable location
        try {
            log.info("Copying SSH keys to /tmp/.ssh");
            ProcessBuilder copyPb = new ProcessBuilder(
                "sh", "-c",
                "cp -r /root/.ssh /tmp/.ssh 2>&1 && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag 2>&1 && ls -la /tmp/.ssh/pqdag"
            );
            copyPb.redirectErrorStream(true);
            Process copyProc = copyPb.start();
            String copyOutput = readProcessOutput(copyProc);
            int copyExit = copyProc.waitFor();
            log.info("SSH key copy exit code: {}, output: {}", copyExit, copyOutput);
        } catch (Exception e) {
            log.error("Failed to copy SSH keys", e);
            throw e;
        }

        // Execute the script on the host via SSH using the pqdag key
        String scriptPath = clientScriptsPath + "/start-all";
        String remoteCommand = "cd " + clientScriptsPath + " && python3 " + scriptPath + " " + pqdagInstallationPath;
        
        log.info("Remote command: {}", remoteCommand);
        log.info("About to execute SSH command");
        
        ProcessBuilder pb = new ProcessBuilder(
            "ssh",
            "-i", "/tmp/.ssh/pqdag",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "ubuntu@172.17.0.1",
            remoteCommand
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        log.info("SSH process started, reading output");
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        log.info("SSH command exit code: {}, output length: {}", exitCode, output.length());
        log.info("Output: {}", output);
        
        if (exitCode != 0) {
            return ClusterStatusResponse.builder()
                    .status("error")
                    .message("Failed to start cluster")
                    .output(output)
                    .build();
        }
        
        return ClusterStatusResponse.builder()
                .status("success")
                .message("Cluster started successfully")
                .output(output)
                .build();
    }

    /**
     * Stop PQDAG cluster
     */
    public ClusterStatusResponse stopCluster() throws Exception {
        log.info("Stopping PQDAG cluster");

        // First ensure SSH keys are copied to writable location
        try {
            ProcessBuilder copyPb = new ProcessBuilder(
                "sh", "-c",
                "cp -r /root/.ssh /tmp/.ssh 2>/dev/null || true && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag"
            );
            copyPb.start().waitFor();
        } catch (Exception e) {
            log.warn("Failed to copy SSH keys, they may already exist", e);
        }

        // Execute the script on the host via SSH using the pqdag key
        String scriptPath = clientScriptsPath + "/stop-all";
        String remoteCommand = "cd " + clientScriptsPath + " && python3 " + scriptPath + " " + pqdagInstallationPath;
        
        log.info("Executing remote command via SSH: {}", remoteCommand);
        
        ProcessBuilder pb = new ProcessBuilder(
            "ssh",
            "-i", "/tmp/.ssh/pqdag",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "ubuntu@172.17.0.1",
            remoteCommand
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        
        log.info("Command exit code: {}", exitCode);
        
        if (exitCode != 0) {
            return ClusterStatusResponse.builder()
                    .status("error")
                    .message("Failed to stop cluster")
                    .output(output)
                    .build();
        }
        
        return ClusterStatusResponse.builder()
                .status("success")
                .message("Cluster stopped successfully")
                .output(output)
                .build();
    }

    /**
     * Restart PQDAG cluster
     */
    public ClusterStatusResponse restartCluster() throws Exception {
        log.info("Restarting PQDAG cluster");
        
        // Stop first
        ClusterStatusResponse stopResponse = stopCluster();
        if (!"success".equals(stopResponse.getStatus())) {
            return stopResponse;
        }
        
        // Wait a bit
        Thread.sleep(2000);
        
        // Start again
        return startCluster();
    }

    /**
     * Clear all Java processes on master, workers and client machine
     */
    public ClusterStatusResponse clearJavaProcesses() throws Exception {
        log.info("Clearing all Java processes on cluster");
        
        // First ensure SSH keys are copied
        try {
            ProcessBuilder copyPb = new ProcessBuilder(
                "sh", "-c",
                "cp -r /root/.ssh /tmp/.ssh 2>/dev/null || true && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag"
            );
            copyPb.start().waitFor();
        } catch (Exception e) {
            log.warn("Failed to copy SSH keys", e);
        }

        // Read master and workers files
        Path masterFile = Paths.get("/app/storage/scripts/master");
        Path workersFile = Paths.get("/app/storage/scripts/workers");
        
        List<String> nodes = new ArrayList<>();
        
        // Add client machine first
        nodes.add(clientMachineIp);
        
        // Add master
        if (Files.exists(masterFile)) {
            String masterIp = Files.readString(masterFile).trim();
            nodes.add(masterIp);
        }
        
        // Add workers
        if (Files.exists(workersFile)) {
            List<String> workers = Files.readAllLines(workersFile).stream()
                    .map(String::trim)
                    .filter(line -> !line.isEmpty())
                    .collect(Collectors.toList());
            nodes.addAll(workers);
        }
        
        log.info("Clearing Java processes on {} nodes", nodes.size());
        
        StringBuilder output = new StringBuilder();
        int successCount = 0;
        
        // Get master IP for comparison
        String masterIp = null;
        if (Files.exists(masterFile)) {
            masterIp = Files.readString(masterFile).trim();
        }
        
        for (String node : nodes) {
            try {
                log.info("Clearing Java processes on node: {}", node);
                
                // Determine which JAR file to kill based on node type
                String killCommand;
                if (node.equals(clientMachineIp)) {
                    // Client machine: kill client.jar
                    killCommand = "pkill -9 -f 'client.jar' || true";
                } else if (node.equals(masterIp)) {
                    // Master: kill master.jar
                    killCommand = "pkill -9 -f 'master.jar' || true";
                } else {
                    // Workers: kill worker.jar
                    killCommand = "pkill -9 -f 'worker.jar' || true";
                }
                
                log.info("Executing on {}: {}", node, killCommand);
                
                ProcessBuilder pb = new ProcessBuilder(
                    "ssh",
                    "-i", "/tmp/.ssh/pqdag",
                    "-o", "StrictHostKeyChecking=no",
                    "-o", "UserKnownHostsFile=/dev/null",
                    "-o", "LogLevel=ERROR",
                    "ubuntu@" + node,
                    killCommand
                );
                pb.redirectErrorStream(true);
                Process process = pb.start();
                String nodeOutput = readProcessOutput(process);
                int exitCode = process.waitFor();
                
                if (exitCode == 0 || exitCode == 1) {  // 0 or 1 are ok (1 means no process found)
                    output.append("Cleared ").append(node).append("\n");
                    successCount++;
                } else {
                    output.append("Warning: ").append(node).append(" returned exit code ").append(exitCode).append(": ").append(nodeOutput).append("\n");
                }
            } catch (Exception e) {
                log.warn("Failed to clear Java processes on node: {}", node, e);
                output.append("Failed: ").append(node).append(" - ").append(e.getMessage()).append("\n");
            }
        }
        
        log.info("Cleared Java processes on {}/{} nodes", successCount, nodes.size());
        
        // Wait for ports to be released
        log.info("Waiting for ports to be released...");
        Thread.sleep(3000);
        
        return ClusterStatusResponse.builder()
                .status("success")
                .message("Cleared Java processes on " + successCount + "/" + nodes.size() + " nodes (waited 3s for ports)")
                .output(output.toString())
                .build();
    }

    /**
     * Execute a SPARQL query
     */
    public QueryExecutionResponse executeQuery(QueryExecutionRequest request) throws Exception {
        log.info("Executing query: {} on dataset: {}", request.getQueryFile(), request.getDataset());

        // Build the query file path on the client machine
        // Example: /home/ubuntu/queries/watdiv/C3.in
        String queryFileOnClient = clientQueriesPath + "/" + request.getDataset() + "/" + request.getQueryFile();
        
        log.info("Query file path on client: {}", queryFileOnClient);
        
        // First ensure SSH keys are copied
        try {
            ProcessBuilder copyPb = new ProcessBuilder(
                "sh", "-c",
                "cp -r /root/.ssh /tmp/.ssh 2>/dev/null || true && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag"
            );
            copyPb.start().waitFor();
        } catch (Exception e) {
            log.warn("Failed to copy SSH keys", e);
        }

        // Kill any existing Java client processes on the client machine to avoid port conflicts
        try {
            log.info("Killing existing Java client processes on client machine...");
            ProcessBuilder killPb = new ProcessBuilder(
                "ssh",
                "-i", "/tmp/.ssh/pqdag",
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "LogLevel=ERROR",
                "ubuntu@" + clientMachineIp,
                "pkill -f 'java -jar.*client.jar' || true"
            );
            killPb.start().waitFor();
            Thread.sleep(1000); // Wait for processes to die
            log.info("Existing Java processes killed");
        } catch (Exception e) {
            log.warn("Failed to kill existing Java processes", e);
        }

        // Execute query using client.jar on the client machine
        // Example: java -jar /home/ubuntu/client.jar "192.168.165.27" ~/queries/watdiv/C3.in 0
        long startTime = System.currentTimeMillis();
        
        String masterIp = request.getMasterIp() != null ? request.getMasterIp() : "192.168.165.27";
        int planNumber = request.getPlanNumber() != null ? request.getPlanNumber() : 0;
        
        String remoteCommand = "/opt/jdk-11/bin/java -jar " + clientJarPath + " \"" + masterIp + "\" " + queryFileOnClient + " " + planNumber;
        
        log.info("Executing query on client machine {}: {}", clientMachineIp, remoteCommand);
        
        ProcessBuilder pb = new ProcessBuilder(
            "ssh",
            "-i", "/tmp/.ssh/pqdag",
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-o", "LogLevel=ERROR",
            "ubuntu@" + clientMachineIp,
            remoteCommand
        );
        pb.redirectErrorStream(true);

        Process process = pb.start();
        String output = readProcessOutput(process);
        
        int exitCode = process.waitFor();
        long executionTime = System.currentTimeMillis() - startTime;
        
        // Filter out SSH warnings
        String cleanOutput = Arrays.stream(output.split("\n"))
                .filter(line -> !line.startsWith("Warning:"))
                .collect(Collectors.joining("\n"));
        
        if (exitCode != 0) {
            return QueryExecutionResponse.builder()
                    .status("error")
                    .message("Query execution failed")
                    .queryFile(request.getQueryFile())
                    .executionTimeMs(executionTime)
                    .output(cleanOutput)
                    .build();
        }
        
        // Parse results
        List<String> results = parseQueryResults(cleanOutput);
        
        QueryExecutionResponse response = QueryExecutionResponse.builder()
                .status("success")
                .message("Query executed successfully")
                .queryFile(request.getQueryFile())
                .executionTimeMs(executionTime)
                .resultCount(results.size())
                .output(cleanOutput)
                .results(results)
                .build();
        
        // Restart cluster after query execution for cold execution next time (async)
        log.info("Scheduling cluster restart for cold execution...");
        new Thread(() -> {
            try {
                Thread.sleep(2000); // Wait a bit before restarting
                log.info("Restarting cluster...");
                restartCluster();
                log.info("Cluster restarted successfully");
            } catch (Exception e) {
                log.warn("Failed to restart cluster after query execution", e);
            }
        }).start();
        
        return response;
    }

    /**
     * Parse query results from output
     */
    private List<String> parseQueryResults(String output) {
        List<String> results = new ArrayList<>();
        String[] lines = output.split("\n");
        
        for (String line : lines) {
            // Filter result lines (adjust based on actual output format)
            if (line.trim().startsWith("?") || line.contains("http://")) {
                results.add(line.trim());
            }
        }
        
        return results;
    }

    /**
     * Get list of available PQDAG datasets from pqdag_data directory
     */
    public List<String> getPqdagDatasets() {
        try {
            // List directories in pqdag_data on master node via SSH
            ProcessBuilder pb = new ProcessBuilder(
                "ssh",
                "-i", "/tmp/.ssh/pqdag",
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "LogLevel=ERROR",
                "ubuntu@172.17.0.1",
                "ls -1 " + pqdagDataPath
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();
            String output = readProcessOutput(process);
            int exitCode = process.waitFor();
            
            if (exitCode == 0) {
                return Arrays.stream(output.split("\n"))
                        .filter(line -> !line.trim().isEmpty())
                        .filter(line -> !line.startsWith("Warning:"))
                        .sorted()
                        .collect(Collectors.toList());
            }
        } catch (Exception e) {
            log.error("Error listing PQDAG datasets", e);
        }
        return Collections.emptyList();
    }

    /**
     * Get current configured dataset from config.properties
     */
    public String getCurrentDataset() {
        try {
            ProcessBuilder pb = new ProcessBuilder(
                "ssh",
                "-i", "/tmp/.ssh/pqdag",
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-o", "LogLevel=ERROR",
                "ubuntu@172.17.0.1",
                "grep '^DB_DEFAULT=' " + pqdagInstallationPath + "/conf/config.properties | cut -d'=' -f2"
            );
            pb.redirectErrorStream(true);
            Process process = pb.start();
            String output = readProcessOutput(process).trim();
            int exitCode = process.waitFor();
            
            if (exitCode == 0 && !output.isEmpty()) {
                // Filter out warning messages
                String[] lines = output.split("\n");
                for (String line : lines) {
                    if (!line.startsWith("Warning:") && !line.trim().isEmpty()) {
                        return line.trim();
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error getting current dataset", e);
        }
        return null;
    }

    /**
     * Set dataset in config.properties on master and all workers
     */
    public ClusterStatusResponse setDataset(String dataset) {
        log.info("Setting dataset to: {}", dataset);
        
        try {
            // First ensure SSH keys are copied
            try {
                log.info("Copying SSH keys");
                ProcessBuilder copyPb = new ProcessBuilder(
                    "sh", "-c",
                    "cp -r /root/.ssh /tmp/.ssh 2>/dev/null || true && chmod 700 /tmp/.ssh && chmod 600 /tmp/.ssh/pqdag"
                );
                copyPb.start().waitFor();
            } catch (Exception e) {
                log.warn("Failed to copy SSH keys", e);
            }

            // Update config.properties on master and all workers
            String configPath = pqdagInstallationPath + "/conf/config.properties";
            String sedCommand = "sed -i 's/^DB_DEFAULT=.*/DB_DEFAULT=" + dataset + "/' " + configPath;
            
            log.info("Config path: {}", configPath);
            log.info("Sed command: {}", sedCommand);
            
            // Read master and workers files from container's storage path
            Path masterFile = Paths.get("/app/storage/scripts/master");
            Path workersFile = Paths.get("/app/storage/scripts/workers");
            
            log.info("Master file: {}, exists: {}", masterFile, Files.exists(masterFile));
            log.info("Workers file: {}, exists: {}", workersFile, Files.exists(workersFile));
            
            List<String> nodes = new ArrayList<>();
            if (Files.exists(masterFile)) {
                String masterIp = Files.readString(masterFile).trim();
                log.info("Master IP: {}", masterIp);
                nodes.add(masterIp);
            }
            if (Files.exists(workersFile)) {
                List<String> workers = Files.readAllLines(workersFile).stream()
                        .map(String::trim)
                        .filter(line -> !line.isEmpty())
                        .collect(Collectors.toList());
                log.info("Workers: {}", workers);
                nodes.addAll(workers);
            }
            
            log.info("Total nodes to update: {}", nodes.size());
            
            StringBuilder output = new StringBuilder();
            boolean success = true;
            
            // Update config on all nodes
            for (String node : nodes) {
                log.info("Updating node: {}", node);
                ProcessBuilder pb = new ProcessBuilder(
                    "ssh",
                    "-i", "/tmp/.ssh/pqdag",
                    "-o", "StrictHostKeyChecking=no",
                    "-o", "UserKnownHostsFile=/dev/null",
                    "-o", "LogLevel=ERROR",
                    "ubuntu@" + node,
                    sedCommand
                );
                pb.redirectErrorStream(true);
                Process process = pb.start();
                String nodeOutput = readProcessOutput(process);
                int exitCode = process.waitFor();
                
                log.info("Node {} exit code: {}, output: {}", node, exitCode, nodeOutput);
                
                if (exitCode == 0) {
                    output.append("Updated ").append(node).append("\n");
                } else {
                    output.append("Failed to update ").append(node).append(": ").append(nodeOutput).append("\n");
                    success = false;
                }
            }
            
            if (success) {
                return ClusterStatusResponse.builder()
                        .status("success")
                        .message("Dataset changed to: " + dataset)
                        .output(output.toString())
                        .build();
            } else {
                return ClusterStatusResponse.builder()
                        .status("error")
                        .message("Failed to update dataset on some nodes")
                        .output(output.toString())
                        .build();
            }
            
        } catch (Exception e) {
            log.error("Error setting dataset", e);
            return ClusterStatusResponse.builder()
                    .status("error")
                    .message("Exception while setting dataset: " + e.getMessage())
                    .build();
        }
    }

    /**
     * Read process output
     */
    private String readProcessOutput(Process process) throws IOException {
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
                log.debug("[PROCESS] {}", line);
            }
        }
        return output.toString();
    }
}

package com.pqdag.service;

import com.pqdag.model.FragmentationResult;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class FragmentationService {

    @Value("${app.storage.rawdata-path}")
    private String rawdataPath;

    @Value("${app.storage.bindata-path}")
    private String bindataPath;

    @Value("${app.storage.outputdata-path}")
    private String outputdataPath;

    @Value("${app.docker.image-name}")
    private String dockerImageName;

    @Autowired
    private FileStorageService fileStorageService;

    /**
     * Execute fragmentation using Docker
     */
    public FragmentationResult executeFragmentation(boolean cleanAfter) throws IOException, InterruptedException {
        // Get absolute paths
        Path rawdataDir = Paths.get(rawdataPath).toAbsolutePath().normalize();
        Path bindataDir = Paths.get(bindataPath).toAbsolutePath().normalize();
        Path outputdataDir = Paths.get(outputdataPath).toAbsolutePath().normalize();

        // Clean bindata and outputdata before execution
        cleanDirectory(bindataDir);
        cleanDirectory(outputdataDir);

        // Build Docker command
        List<String> command = new ArrayList<>();
        command.add("docker");
        command.add("run");
        command.add("--rm");
        // Run with current user's UID:GID to avoid permission issues
        command.add("--user");
        String userId = System.getProperty("user.name");
        try {
            // Get current user's UID:GID on Linux
            ProcessBuilder idBuilder = new ProcessBuilder("id", "-u");
            Process idProcess = idBuilder.start();
            String uid = new BufferedReader(new InputStreamReader(idProcess.getInputStream()))
                    .readLine().trim();
            
            idBuilder = new ProcessBuilder("id", "-g");
            idProcess = idBuilder.start();
            String gid = new BufferedReader(new InputStreamReader(idProcess.getInputStream()))
                    .readLine().trim();
            
            command.add(uid + ":" + gid);
        } catch (Exception e) {
            // Fallback to current user if id command fails (e.g., on Windows)
            command.add(userId);
        }
        command.add("-v");
        command.add(rawdataDir + ":/rawdata");
        command.add("-v");
        command.add(bindataDir + ":/bindata");
        command.add("-v");
        command.add(outputdataDir + ":/outputdata");
        command.add(dockerImageName);
        command.add("/rawdata/");
        command.add("/bindata/data.nt");

        // Execute Docker command
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        // Capture output
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
                System.out.println("[DOCKER] " + line); // Log to console
            }
        }

        int exitCode = process.waitFor();

        if (exitCode != 0) {
            return new FragmentationResult(
                    false,
                    "Docker execution failed with exit code: " + exitCode,
                    0, 0, 0.0, 0,
                    output.toString(),
                    null, null, null, null, null
            );
        }

        // Parse output
        FragmentationResult result = parseDockerOutput(output.toString());

        // Count fragments
        int fragmentCount = countFragments(outputdataDir);
        result.setFragmentCount(fragmentCount);

        // Clean after execution if requested
        if (cleanAfter) {
            fileStorageService.clearRawdata();
            fileStorageService.clearBindata();
        }

        return result;
    }

    /**
     * Parse Docker output to extract metrics
     */
    private FragmentationResult parseDockerOutput(String output) {
        FragmentationResult result = new FragmentationResult();
        result.setSuccess(true);
        result.setMessage("Fragmentation completed successfully");
        result.setDockerOutput(output);

        // Patterns to match actual output format
        // Example: "Total number of triples: 110828 records"
        Pattern triplesPattern = Pattern.compile("Total number of triples:\\s*(\\d+)\\s*records");
        
        // Example: "Done with data encoding in 0.120111 sec"
        Pattern encodingPattern = Pattern.compile("Done with data encoding in\\s*([0-9.]+)\\s*sec");
        
        // Example: "Done with dumping dictionaries in 0.00635933 sec"
        Pattern dictionariesPattern = Pattern.compile("Done with dumping dictionaries in\\s*([0-9.]+)\\s*sec");
        
        // Example: "Done with Sorting in 0.0997743 sec"
        Pattern sortingPattern = Pattern.compile("Done with Sorting in\\s*([0-9.]+)\\s*sec");
        
        // Example: "Done with Fragmentation in 0.517501 sec"
        Pattern fragmentationPattern = Pattern.compile("Done with Fragmentation in\\s*([0-9.]+)\\s*sec");
        
        // Example: "Done with Fragments re-encoding in 0.655355 sec"
        Pattern reencodingPattern = Pattern.compile("Done with Fragments re-encoding in\\s*([0-9.]+)\\s*sec");
        
        // Example: "Run Finished in 1.47381 sec"
        Pattern totalPattern = Pattern.compile("Run Finished in\\s*([0-9.]+)\\s*sec");

        Matcher m;

        // Extract total triples
        m = triplesPattern.matcher(output);
        if (m.find()) {
            result.setTotalTriples(Long.parseLong(m.group(1)));
        }

        // Extract timings
        m = encodingPattern.matcher(output);
        if (m.find()) {
            result.setEncodingTime(Double.parseDouble(m.group(1)));
        }

        m = dictionariesPattern.matcher(output);
        if (m.find()) {
            result.setDictionariesTime(Double.parseDouble(m.group(1)));
        }

        m = sortingPattern.matcher(output);
        if (m.find()) {
            result.setSortingTime(Double.parseDouble(m.group(1)));
        }

        m = fragmentationPattern.matcher(output);
        if (m.find()) {
            result.setFragmentationTime(Double.parseDouble(m.group(1)));
        }

        m = reencodingPattern.matcher(output);
        if (m.find()) {
            result.setReencodingTime(Double.parseDouble(m.group(1)));
        }

        m = totalPattern.matcher(output);
        if (m.find()) {
            result.setExecutionTimeSeconds(Double.parseDouble(m.group(1)));
        }

        // Calculate throughput
        if (result.getTotalTriples() > 0 && result.getExecutionTimeSeconds() > 0) {
            result.setThroughput((long) (result.getTotalTriples() / result.getExecutionTimeSeconds()));
        }

        return result;
    }

    /**
     * Count fragment files in output directory
     */
    private int countFragments(Path outputDir) throws IOException {
        if (!Files.exists(outputDir)) {
            return 0;
        }

        return (int) Files.walk(outputDir)
                .filter(Files::isRegularFile)
                .filter(p -> p.toString().endsWith(".data"))
                .count();
    }

    /**
     * Clean a directory (remove all files and subdirectories)
     */
    private void cleanDirectory(Path directory) throws IOException {
        if (!Files.exists(directory)) {
            Files.createDirectories(directory);
            return;
        }

        Files.walk(directory)
                .sorted(Comparator.reverseOrder()) // Delete files before directories
                .filter(p -> !p.equals(directory)) // Keep the root directory
                .forEach(p -> {
                    try {
                        Files.delete(p);
                    } catch (IOException e) {
                        System.err.println("Failed to delete: " + p);
                    }
                });
    }
}

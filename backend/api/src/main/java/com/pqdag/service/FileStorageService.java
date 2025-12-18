package com.pqdag.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
public class FileStorageService {

    @Value("${app.storage.rawdata-path}")
    private String rawdataPath;

    @Value("${app.storage.bindata-path}")
    private String bindataPath;

    @Value("${app.storage.outputdata-path}")
    private String outputdataPath;

    /**
     * Upload files to rawdata directory
     */
    public List<String> uploadFiles(MultipartFile[] files) throws IOException {
        List<String> uploadedFiles = new ArrayList<>();
        Path rawdataDir = Paths.get(rawdataPath).toAbsolutePath().normalize();

        // Create directory if it doesn't exist
        if (!Files.exists(rawdataDir)) {
            Files.createDirectories(rawdataDir);
        }

        for (MultipartFile file : files) {
            if (file.isEmpty()) {
                continue;
            }

            // Validate file extension
            String fileName = file.getOriginalFilename();
            if (fileName == null || (!fileName.endsWith(".nt") && !fileName.endsWith(".ttl"))) {
                throw new IOException("Invalid file format. Only .nt and .ttl files are allowed: " + fileName);
            }

            // Save file
            Path targetPath = rawdataDir.resolve(fileName);
            Files.copy(file.getInputStream(), targetPath, StandardCopyOption.REPLACE_EXISTING);
            uploadedFiles.add(fileName);
        }

        return uploadedFiles;
    }

    /**
     * Get total size of files in rawdata directory
     */
    public long getRawdataSize() throws IOException {
        Path rawdataDir = Paths.get(rawdataPath).toAbsolutePath().normalize();
        if (!Files.exists(rawdataDir)) {
            return 0;
        }

        return Files.walk(rawdataDir)
                .filter(Files::isRegularFile)
                .filter(p -> p.toString().endsWith(".nt") || p.toString().endsWith(".ttl"))
                .mapToLong(p -> {
                    try {
                        return Files.size(p);
                    } catch (IOException e) {
                        return 0;
                    }
                })
                .sum();
    }

    /**
     * List files in rawdata directory
     */
    public List<String> listRawdataFiles() throws IOException {
        Path rawdataDir = Paths.get(rawdataPath).toAbsolutePath().normalize();
        if (!Files.exists(rawdataDir)) {
            return new ArrayList<>();
        }

        return Files.walk(rawdataDir)
                .filter(Files::isRegularFile)
                .filter(p -> p.toString().endsWith(".nt") || p.toString().endsWith(".ttl"))
                .map(p -> p.getFileName().toString())
                .toList();
    }

    /**
     * Clear rawdata directory
     */
    public void clearRawdata() throws IOException {
        Path rawdataDir = Paths.get(rawdataPath).toAbsolutePath().normalize();
        if (!Files.exists(rawdataDir)) {
            return;
        }

        Files.walk(rawdataDir)
                .filter(Files::isRegularFile)
                .forEach(p -> {
                    try {
                        Files.delete(p);
                    } catch (IOException e) {
                        // Ignore
                    }
                });
    }

    /**
     * Clear bindata directory (temporary files and subdirectories)
     */
    public void clearBindata() throws IOException {
        Path bindataDir = Paths.get(bindataPath).toAbsolutePath().normalize();
        if (!Files.exists(bindataDir)) {
            return;
        }

        Files.walk(bindataDir)
                .sorted(Comparator.reverseOrder()) // Delete files before directories
                .filter(p -> !p.equals(bindataDir)) // Keep the root directory
                .forEach(p -> {
                    try {
                        Files.delete(p);
                    } catch (IOException e) {
                        // Ignore
                    }
                });
    }
}

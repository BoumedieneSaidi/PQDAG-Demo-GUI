package com.pqdag.controller;

import com.pqdag.model.UploadResponse;
import com.pqdag.service.FileStorageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/files")
public class FileController {

    @Autowired
    private FileStorageService fileStorageService;

    /**
     * Upload RDF files to rawdata directory
     */
    @PostMapping("/upload")
    public ResponseEntity<UploadResponse> uploadFiles(@RequestParam("files") MultipartFile[] files) {
        try {
            List<String> uploadedFiles = fileStorageService.uploadFiles(files);
            long totalSize = fileStorageService.getRawdataSize();

            UploadResponse response = new UploadResponse(
                    true,
                    "Files uploaded successfully",
                    uploadedFiles,
                    totalSize,
                    uploadedFiles.size()
            );

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            UploadResponse response = new UploadResponse(
                    false,
                    "Upload failed: " + e.getMessage(),
                    null,
                    0,
                    0
            );
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * List files in rawdata directory
     */
    @GetMapping("/list")
    public ResponseEntity<Map<String, Object>> listFiles() {
        try {
            List<String> files = fileStorageService.listRawdataFiles();
            long totalSize = fileStorageService.getRawdataSize();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("files", files);
            response.put("fileCount", files.size());
            response.put("totalSize", totalSize);

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to list files: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * Clear rawdata directory
     */
    @DeleteMapping("/clear")
    public ResponseEntity<Map<String, Object>> clearRawdata() {
        try {
            fileStorageService.clearRawdata();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Rawdata directory cleared");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Failed to clear rawdata: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}

package com.pqdag.controller;

import com.pqdag.model.FragmentationRequest;
import com.pqdag.model.FragmentationResult;
import com.pqdag.service.FragmentationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/fragmentation")
public class FragmentationController {

    @Autowired
    private FragmentationService fragmentationService;

    /**
     * Start fragmentation process
     */
    @PostMapping("/start")
    public ResponseEntity<FragmentationResult> startFragmentation(
            @RequestBody(required = false) FragmentationRequest request) {
        try {
            boolean cleanAfter = request != null ? request.isCleanAfter() : true;
            FragmentationResult result = fragmentationService.executeFragmentation(cleanAfter);
            
            if (result.isSuccess()) {
                return ResponseEntity.ok(result);
            } else {
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(result);
            }
        } catch (Exception e) {
            FragmentationResult errorResult = new FragmentationResult();
            errorResult.setSuccess(false);
            errorResult.setMessage("Fragmentation failed: " + e.getMessage());
            errorResult.setDockerOutput(e.toString());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResult);
        }
    }
}

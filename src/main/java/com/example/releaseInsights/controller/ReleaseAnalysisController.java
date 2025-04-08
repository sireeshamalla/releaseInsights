package com.example.releaseInsights.controller;

import com.example.releaseInsights.service.ReleaseAnalysisJob;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.util.Map;

@RestController
@RequestMapping("/api/release")
public class ReleaseAnalysisController {
    private final ReleaseAnalysisJob releaseAnalysisJob;
    private static final Logger logger = LoggerFactory.getLogger(ReleaseAnalysisController.class);

    public ReleaseAnalysisController(ReleaseAnalysisJob releaseAnalysisJob) {
        this.releaseAnalysisJob = releaseAnalysisJob;
    }

    @GetMapping("/analyze")
    public ResponseEntity<Map<String, Object>> triggerAnalysis() throws IOException {
        logger.info("calling release analysis job");
        String summary = releaseAnalysisJob.analyzeLatestRelease();
        return ResponseEntity.ok(Map.of("success", true, "summary", summary));    }

    @GetMapping("/branches")
    public ResponseEntity<Map<String, Boolean>>  branches() throws IOException {
        logger.info("calling release analysis job");
        logger.info("added for testing");

        //String summary = releaseAnalysisJob.analyzeLatestRelease();
        return ResponseEntity.ok(Map.of("success", true));    }
}

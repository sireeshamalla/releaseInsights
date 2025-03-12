package com.example.releaseInsights.controller;

import com.example.releaseInsights.service.ReleaseAnalysisJob;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

@RestController
@RequestMapping("/api/release")
public class ReleaseAnalysisController {
    private final ReleaseAnalysisJob releaseAnalysisJob;
    private static final Logger logger = LoggerFactory.getLogger(ReleaseAnalysisController.class);

    public ReleaseAnalysisController(ReleaseAnalysisJob releaseAnalysisJob) {
        this.releaseAnalysisJob = releaseAnalysisJob;
    }

    @GetMapping("/analyze")
    public String triggerAnalysis() throws IOException {
        logger.info("calling release analysis job");
        releaseAnalysisJob.analyzeLatestRelease();
        return "Release analysis started!";
    }
}

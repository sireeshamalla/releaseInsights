package com.example.releaseInsights.service;
import com.example.releaseInsights.controller.ReleaseAnalysisController;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
public class ReleaseAnalysisJob {

    private static final Logger logger = LoggerFactory.getLogger(ReleaseAnalysisController.class);

    private final GitHubService gitHubService;
    private final GoogleAiService googleAiService;

    public ReleaseAnalysisJob(GitHubService gitHubService, GoogleAiService googleAiService) {
        this.gitHubService = gitHubService;
        this.googleAiService = googleAiService;
    }

    @Scheduled(cron = "0 0 * * *") // Runs every hour, adjust as needed
    public String analyzeLatestRelease() throws IOException {
        logger.info("Starting release analysis job");

        String summary = gitHubService.analyzeLatestReleaseChanges();

        System.out.println("Release Summary: \n" + summary);
        return summary;
    }
}
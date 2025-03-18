package com.example.releaseInsights.service;

import com.example.releaseInsights.config.GitHubConfig;
import org.kohsuke.github.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class GitHubCompareService {
    private static final Logger logger = LoggerFactory.getLogger(GitHubBranchService.class);

    private final GitHubConfig gitHubConfig;
    private final GoogleAiService googleAiService;

    public GitHubCompareService(GitHubConfig gitHubConfig, GoogleAiService googleAiService) {
        this.gitHubConfig = gitHubConfig;
        this.googleAiService = googleAiService;
    }

    public String getBranchDiff( String baseBranch, String newBranch) throws IOException {
        GitHub github = new GitHubBuilder().withOAuthToken(gitHubConfig.getToken()).build();
        GHRepository repository = github.getRepository(gitHubConfig.getRepoOwner() + "/" + gitHubConfig.getRepoName());
        logger.info("Calling getCompare for branches: {} and {}", baseBranch, newBranch);
        logger.info("added for testing");

        // Get comparison between branches
        GHCompare compare = repository.getCompare(baseBranch, newBranch);

        Map<String, String> changesSummary = new LinkedHashMap<>();

        for (GHCommit.File file : compare.getFiles()) {
            String filename = file.getFileName();
            String patch = file.getPatch(); // Get code diff

            if (patch != null) {
                String summary = googleAiService.summarizeCodeDiff(patch);
                changesSummary.put(filename, summary);
            }
        }
        StringBuilder stringBuilder = new StringBuilder();
        for (Map.Entry<String, String> entry : changesSummary.entrySet()) {
            stringBuilder.append(entry.getKey())
                    .append(": ")
                    .append(entry.getValue())
                    .append("\n");
        }
        return stringBuilder.toString();
    }
}
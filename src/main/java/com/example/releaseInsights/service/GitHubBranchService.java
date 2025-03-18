package com.example.releaseInsights.service;

import com.example.releaseInsights.config.GitHubConfig;
import org.json.JSONArray;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.regex.Pattern;

@Service
public class GitHubBranchService {
    private static final Logger logger = LoggerFactory.getLogger(GitHubBranchService.class);

    private static final String GITHUB_API_URL = "https://api.github.com/repos/%s/%s/branches";
    private final GitHubConfig gitHubConfig;

    public GitHubBranchService(GitHubConfig gitHubConfig) {
        this.gitHubConfig = gitHubConfig;
    }

    public List<String> getLatestReleaseBranches() {
        //logger.info("Added for testing");

        String url = String.format(GITHUB_API_URL, gitHubConfig.getRepoOwner(), gitHubConfig.getRepoName());
        logger.info("Requesting URL: {}", url);

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "token " + gitHubConfig.getToken());
//        headers.set("Accept", "application/vnd.github.v3+json");

        HttpEntity<String> entity = new HttpEntity<>(headers);
        ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
        logger.info("Response status: {}", response.getStatusCode());

        if (response.getStatusCode().is2xxSuccessful()) {

            JSONArray branches = new JSONArray(response.getBody());
            List<String> releaseBranches = new ArrayList<>();

        // Extract release branches matching "release-X.Y"
        Pattern pattern = Pattern.compile("release-\\d+\\.\\d+");
        for (int i = 0; i < branches.length(); i++) {
            String branchName = branches.getJSONObject(i).getString("name");
            if (pattern.matcher(branchName).matches()) {
                releaseBranches.add(branchName);
            }
        }

        // Sort branches in descending order (latest first)
        releaseBranches.sort(Comparator.reverseOrder());

        // Return the latest and previous release branch
        return releaseBranches.size() >= 2
                ? Arrays.asList(releaseBranches.get(0), releaseBranches.get(1))
                : Collections.emptyList();
        } else {
            logger.error("Failed to fetch branches: {}", response.getStatusCode());
            return Collections.emptyList();
        }
    }
}
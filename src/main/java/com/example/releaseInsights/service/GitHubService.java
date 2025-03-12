package com.example.releaseInsights.service;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Service
public class GitHubService {
    private final GitHubBranchService branchService;
    private final GitHubCompareService compareService;

    public GitHubService(GitHubBranchService branchService, GitHubCompareService compareService) {
        this.branchService = branchService;
        this.compareService = compareService;
    }

    public String analyzeLatestReleaseChanges() throws IOException {
        List<String> latestBranches = branchService.getLatestReleaseBranches();

        if (latestBranches.size() < 2) {
            return "Not enough release branches found!";
        }

        String latest = latestBranches.get(0);
        String previous = latestBranches.get(1);

        return compareService.getBranchDiff(previous, latest);
    }
}

package com.example.releaseInsights.service;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.List;

@Service
public class GitHubService {
    private static final Logger logger = LoggerFactory.getLogger(GitHubBranchService.class);

    private final GitHubBranchService branchService;
    private final GitHubCompareService compareService;

    public GitHubService(GitHubBranchService branchService, GitHubCompareService compareService) {
        this.branchService = branchService;
        this.compareService = compareService;
    }

    public String analyzeLatestReleaseChanges() throws IOException {
        try {
            List<String> latestBranches = branchService.getLatestReleaseBranches();

            if (latestBranches.size() < 2) {
                return "Not enough release branches found !";
            }

            String latest = latestBranches.get(0);
            String previous = latestBranches.get(1);
            logger.info("Comparing branches: {} and {}", previous, latest);

            return compareService.getBranchDiff(previous, latest);
        } catch (IOException e) {
            logger.error("Error fetching release branches or comparing them", e);
            return "An error occurred while analyzing release changes.";
        }
    }

    static void Fibonacci(int N)
    {
        int num1 = 0, num2 = 1;

        for (int i = 0; i < N; i++) {
            // Print the number
            System.out.print(num1 + " ");

            // Swap
            int num3 = num2 + num1;
            num1 = num2;
            num2 = num3;
        }
    }
}

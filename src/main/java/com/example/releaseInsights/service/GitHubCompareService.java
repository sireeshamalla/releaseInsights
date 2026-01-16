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
                private static final Logger logger = LoggerFactory.getLogger(GitHubCompareService.class);

                private final GitHubConfig gitHubConfig;
                private final GoogleAiService googleAiService;
                private final GitHub github;

                public GitHubCompareService(GitHubConfig gitHubConfig, GoogleAiService googleAiService, GitHub github) {
                    if (gitHubConfig == null || googleAiService == null || github == null) {
                        throw new IllegalArgumentException("Dependencies cannot be null");
                    }
                    this.gitHubConfig = gitHubConfig;
                    this.googleAiService = googleAiService;
                    this.github = github;
                }

                public String getBranchDiff(String baseBranch, String newBranch) throws IOException {
                    logger.info("Fetching comparison for branches: {} and {}", baseBranch, newBranch);

                    GHRepository repository = getRepository();
                    GHCompare compare = repository.getCompare(baseBranch, newBranch);

                    Map<String, String> changesSummary = summarizeChanges(compare);

                    return formatChangesSummary(changesSummary);
                }

                private GHRepository getRepository() throws IOException {
                    return github.getRepository(gitHubConfig.getRepoOwner() + "/" + gitHubConfig.getRepoName());
                }

                private Map<String, String> summarizeChanges(GHCompare compare) throws IOException {
                    Map<String, String> changesSummary = new LinkedHashMap<>();

                    for (GHCommit.File file : compare.getFiles()) {
                        String filename = file.getFileName();
                        String patch = file.getPatch();

                        String summary = (patch != null) ? googleAiService.summarizeCodeDiff(patch) : "No changes found";
                        changesSummary.put(filename, summary);
                    }

                    return changesSummary;
                }

                private String formatChangesSummary(Map<String, String> changesSummary) {
                    StringBuilder stringBuilder = new StringBuilder();
                    changesSummary.forEach((filename, summary) ->
                        stringBuilder.append(filename).append(": ").append(summary).append("\n")
                    );
                    return stringBuilder.toString();
                }
            }
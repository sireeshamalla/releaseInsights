package com.example.releaseInsights.config;

import lombok.Getter;
import lombok.Setter;
import org.kohsuke.github.GitHub;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@ConfigurationProperties(prefix = "github")
@Setter
@Getter
public class GitHubConfig {
//TODO added this comment for testing
    private String token;
    private String repoOwner;
    private String repoName;
    @Value("${github.token}")
    private String githubToken;
    @Bean
    public GitHub gitHub() {
        try {
            return GitHub.connectUsingOAuth(githubToken);
        } catch (Exception e) {
            // Create a dedicated exception class for GitHub connection errors.
            throw new GitHubConnectionException("Error connecting to GitHub.", e);
        }
    }
}

// Dedicated exception class for GitHub connection errors.
class GitHubConnectionException extends RuntimeException {
    public GitHubConnectionException(String message, Throwable cause) {
        super(message, cause);
    }
}

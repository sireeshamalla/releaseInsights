package com.example.releaseInsights.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.example.releaseInsights.client.AiClient;

import java.io.IOException;

@Service
public class GoogleAiService {
    private static final Logger logger = LoggerFactory.getLogger(GoogleAiService.class);

    @Autowired
    private AiClient aiClient;

    public String summarizeCodeDiff(String codeDiff) throws IOException {
        if (aiClient == null) {
            throw new IllegalStateException("AiClient is not initialized");
        }
        String systemPrompt = String.format(
                "You are a smart code analysis assistant. Your job is to create a brief summary of the given code difference (diff) for a file.\n" +
                        "\n" +
                        "Instructions:\n" +
                        "1. Examine the provided code diff and identify the main changes.\n" +
                        "2. Summarize the changes clearly and concisely.\n" +
                        "3. Highlight the most important modifications, additions, and deletions.\n" +
                        "4. Ensure the summary is easy to understand and gives a high-level overview of the changes.\n" +
                        "\n" +
                        "Output Format:\n" +
                        "- [Summary of the key changes in the code diff]\n" +
                        "\n" +
                        "Note: Always prioritize clarity and brevity."
        );
        logger.info("systemprompt: " + systemPrompt);

        try {
            String response = aiClient.callApi(systemPrompt, codeDiff);
            if (response == null) {
                return codeDiff;
            }
            return response;
        } catch (Exception e) {
            logger.error("Error while calling AI API", e);
            throw new RuntimeException("Failed to summarize code diff", e);
        }
    }
    public String analyzeAndSummarize(String codeDiff) throws IOException {
        logger.info("Analyzing and summarizing code diff");

        // Simulate some analysis
        String analysisResult = "Analysis result of the code diff";

        // Summarize the code diff
        String summary = summarizeCodeDiff(codeDiff);

        return analysisResult + "\n" + summary;
    }
}
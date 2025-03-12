package com.example.releaseInsights.service;

import org.springframework.stereotype.Service;
import com.example.releaseInsights.client.AiClient;

import java.io.IOException;

@Service
public class GoogleAiService {

    private AiClient aiClient;

    public String summarizeCodeDiff(String codeDiff) throws IOException {

        String systemPrompt = String.format(
                "You are an intelligent code analysis assistant. Your task is to generate a concise summary of the provided code difference (diff) for a file.\n" +
                        "\n" +
                        "Instructions:\n" +
                        "1. Analyze the provided code diff and identify the key changes.\n" +
                        "2. Summarize the changes in a clear and concise manner.\n" +
                        "3. Focus on the most significant modifications, additions, and deletions.\n" +
                        "4. Ensure the summary is easy to understand and provides a high-level overview of the changes.\n" +
                        "\n" +
                        "Output Format:\n" +
                        "- [Summary of the key changes in the code diff]\n" +
                        "\n" +
                        "Note: Always prioritize clarity and conciseness."
        );
        return aiClient.callApi(systemPrompt, codeDiff);
    }
}
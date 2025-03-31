package com.example.releaseInsights.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;
import org.springframework.stereotype.Component;

@Component
public class AiClientImpl implements AiClient {

    private static final Logger logger = LoggerFactory.getLogger(AiClientImpl.class);

    private ChatClient client;

    public AiClientImpl(ChatModel model) {
        client = ChatClient.builder(model).build();
    }

    public String callApi(String systemPrompt, String input) {

        logger.info("Input received: {} System Prompt: {}", input, systemPrompt); // Format specifiers used for logging
        String response = client.prompt().system(systemPrompt).user(input).call().content();
        logger.info("Response from AI: {}", response); // Format specifier used for logging
        return response;
    }
}
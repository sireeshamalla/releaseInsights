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
        //  .prompt() creates a prompt to pass to the Model.class
        //  .user() sets the "user" message. Pass the input String parameter.
        //  .call() invokes the model.  It returns a CallResponse.
        //  .content() is a simple means of extracting String content from the response.
        //  Have the method return the content of the response.
        logger.info("Input received: {} System Prompt: {}", input, systemPrompt); // Format specifiers used for logging
        String response = client.prompt().system(systemPrompt).user(input).call().content();
        if(response == null) {
            logger.error("Response from AI is null");
            return "Error: Response from AI is null";
        }
        logger.info("Response from AI: {}", response); // Format specifier used for logging
        return response;
    }
}
package com.example.releaseInsights.client;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Answers;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.ai.chat.client.ChatClient;
import org.springframework.ai.chat.model.ChatModel;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AiClientImplTest {
    @Mock
    private ChatModel chatModel;
    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private ChatClient chatClient;

    private AiClientImpl aiClientImpl;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        // Mock ChatClient.builder(model).build() to return our mock chatClient
        var mockedStatic = mockStatic(ChatClient.class);
        mockedStatic.when(() -> ChatClient.builder(chatModel)).thenReturn(mock(ChatClient.Builder.class));
        when(ChatClient.builder(chatModel).build()).thenReturn(chatClient);
        aiClientImpl = new AiClientImpl(chatModel);
    }

    @Test
    void testCallApi() {
        String systemPrompt = "system";
        String input = "input";
        String expectedResponse = "response";

        // Mock the chained calls
        when(chatClient.prompt().system(systemPrompt).user(input).call().content()).thenReturn(expectedResponse);

        String result = aiClientImpl.callApi(systemPrompt, input);
        assertEquals(expectedResponse, result);
    }
}

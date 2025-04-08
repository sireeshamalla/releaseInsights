#!/bin/bash

# Enable debug mode
set -x

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY is not set."
  exit 1
fi

# Get the story details table from the input
story_table="$STORY_TABLE"
echo "Story Table: $story_table"  # Debugging line

# Create a detailed prompt message for the summary
prompt_message="You are an intelligent assistant. Your task is to generate a concise summary of the Jira stories based on their descriptions.\n\nInstructions:\n1. Analyze the provided table of Jira stories.\n2. Summarize the key details and objectives of the stories.\n3. Ensure the summary is clear, concise, and highlights the critical aspects of the stories.\n\nTable of Jira Stories:\n${story_table}"
escaped_prompt_message=$(echo "$prompt_message" | jq -sRr @json)
echo "Escaped Prompt Message: $escaped_prompt_message"  # Debugging line

# Call Gemini AI to get the summary
summary_response=$(curl -s -X POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY} \
  -H 'Content-Type: application/json' \
  -d @<(echo '{
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": '"$escaped_prompt_message"'
          }
        ]
      }
    ],
    "generationConfig": {
      "temperature": 1,
      "topK": 40,
      "topP": 0.95,
      "maxOutputTokens": 8192,
      "responseMimeType": "text/plain"
    }
  }'))

# Extract the summary text
summary_text=$(echo "$summary_response" | jq -r '.candidates[0].content.parts[0].text')
echo "Summary Text: $summary_text"  # Debugging line
echo "::set-output name=gemini_stories_summary::${summary_text}"

# Disable debug mode
set +x
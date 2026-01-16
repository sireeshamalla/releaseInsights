#!/bin/bash

# Enable debug mode
set -x

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY is not set."
  exit 1
fi

# Get the summary_table from the input
summary_table="$SUMMARY_TABLE"
echo "Summary Table: $summary_table"  # Debugging line


# Create a detailed prompt message for the final summary
final_prompt_message="You are an intelligent code analysis assistant. Your task is to generate a concise summary of the critical changes for the given release based on the provided table of code changes.\n\nInstructions:\n1. Analyze the provided table of code changes for each file.\n2. Identify and summarize the critical changes that have a significant impact on the functionality, performance, or security of the application.\n3. Focus on the most important modifications, additions, and deletions.\n4. Ignore negligible changes such as logging statements, spaces, and new lines.\n5. Do not include file-level changes in the summary.\n6. Ensure the summary is clear, concise, and highlights the critical aspects of the changes.\n\nOutput Format:\n- [Summary of the highlights the critical aspects of the changes.]\n\nNote: Always prioritize clarity and conciseness.\n\n${summary_table}"
escaped_final_prompt_message=$(echo "$final_prompt_message" | jq -sRr @json)
echo "Escaped Final Prompt Message: $escaped_final_prompt_message"  # Debugging line

# Call Gemini AI to get the final summary
final_summary=$(curl -s -X POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY} \
  -H 'Content-Type: application/json' \
  -d @<(echo '{
    "contents": [
      {
        "role": "user",
        "parts": [
          {
            "text": '"$escaped_final_prompt_message"'
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
echo "Escaped Final Prompt Message: $escaped_final_prompt_message"  # Debugging line

final_text=$(echo "$final_summary" | jq -r '.candidates[0].content.parts[0].text')
echo "Final Text: $final_text"  # Debugging line
# Escape newlines and special characters in the final text
escaped_final_text=$(echo "$final_text" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')

# Export gemini_summary as an environment variable
echo "gemini_summary=$escaped_final_text" >> $GITHUB_ENV
# Disable debug mode
set +x
#!/bin/bash

          JIRA_EMAIL: ${{ secrets.JIRA_EMAIL }}
          JIRA_API_TOKEN: ${{ secrets.JIRA_API_TOKEN }}
          JIRA_DOMAIN: sirimalla102.atlassian.net
          BOARD_ID: 34
          FIX_VERSION: release-25.69
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}

# Fetch stories with Feature Link, description, and status
response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
"https://$JIRA_DOMAIN/rest/agile/1.0/board/$BOARD_ID/issue?jql=issuetype=Story%20AND%20fixVersion=%22$FIX_VERSION%22%20AND%20'Feature%20Link'%20is%20not%20EMPTY&fields=customfield_10091,status"
# Parse the response to extract stories
stories=$(echo "$response" | jq -r '.issues[] | "\(.fields.customfield_10091)=\(.fields.status.name)"')

# Initialize associative arrays
declare -A feature_map
declare -A feature_status_count
declare -A feature_descriptions

# Group stories by feature and count statuses
while IFS= read -r story; do
  feature_url=$(echo "$story" | cut -d'=' -f1)
  status=$(echo "$story" | cut -d'=' -f2)

  # Increment total story count for the feature
  feature_map["$feature_url"]=$((feature_map["$feature_url"] + 1))

  # Increment "Done" story count for the feature
  if [[ "$status" == "Done" ]]; then
    feature_status_count["$feature_url"]=$((feature_status_count["$feature_url"] + 1))
  fi
done <<< "$stories"

# Fetch and summarize each feature's description
for feature_url in "${!feature_map[@]}"; do
  # Extract feature key from URL
  feature_key=$(basename "$feature_url")

  # Fetch feature details
  feature_response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    "https://$JIRA_DOMAIN/rest/api/3/issue/$feature_key?fields=description")
  feature_description=$(echo "$feature_response" | jq -r '.fields.description | @text')

  # Summarize feature description using Gemini AI
  prompt_message="Summarize the following feature description:\n\n${feature_description}"
  escaped_prompt_message=$(echo "$prompt_message" | jq -sRr @json)
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
  feature_summary=$(echo "$summary_response" | jq -r '.candidates[0].content.parts[0].text')

  # Store the feature description and summary
  feature_descriptions["$feature_url"]="$feature_summary"
done

# Display the results
html_table="<table border='1'><tr><th>Feature</th><th>Summary</th><th>Completion Percentage</th></tr>"
for feature_url in "${!feature_map[@]}"; do
  total_stories=${feature_map["$feature_url"]}
  done_stories=${feature_status_count["$feature_url"]}
  completion_percentage=$((100 * done_stories / total_stories))
  feature_summary=${feature_descriptions["$feature_url"]}
  html_table="${html_table}<tr><td>${feature_url}</td><td>${feature_summary}</td><td>${completion_percentage}%</td></tr>"
done
html_table="${html_table}</table>"

# Export the HTML table to the GitHub environment
echo "html_table=$html_table" >> $GITHUB_ENV
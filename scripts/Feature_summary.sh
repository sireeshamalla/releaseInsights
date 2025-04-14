#!/bin/bash
echo "Fetching Jira Features for the given Fix Version..."

# Fetch stories with Feature Link, description, and status
echo "Fetching stories from Jira API..."
response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
"https://$JIRA_DOMAIN/rest/agile/1.0/board/$BOARD_ID/issue?jql=issuetype=Story%20AND%20fixVersion=%22$FIX_VERSION%22%20AND%20'Feature%20Link'%20is%20not%20EMPTY&fields=customfield_10091,status")
echo "Response from Jira API: $response"

# Parse the response to extract stories
echo "Parsing stories..."
stories=$(echo "$response" | jq -r '.issues[] | "\(.fields.customfield_10091)=\(.fields.status.name)"')
echo "Parsed stories: $stories"

# Initialize associative arrays
declare -A feature_map
declare -A feature_status_count
declare -A feature_descriptions

# Group stories by feature and count statuses
echo "Grouping stories by feature..."
while IFS= read -r story; do
  feature_url=$(echo "$story" | cut -d'=' -f1)
  status=$(echo "$story" | cut -d'=' -f2)

  echo "Processing story with Feature Link: $feature_url and Status: $status"

  # Increment total story count for the feature
  feature_map["$feature_url"]=$((feature_map["$feature_url"] + 1))

  # Increment "Done" story count for the feature
  if [[ "$status" == "Done" ]]; then
    feature_status_count["$feature_url"]=$((feature_status_count["$feature_url"] + 1))
  fi
done <<< "$stories"

# Fetch and summarize each feature's description
echo "Fetching and summarizing feature descriptions..."
for feature_url in "${!feature_map[@]}"; do
  echo "Fetching details for feature: $feature_url"

  # Extract feature key from URL
  feature_key=$(basename "$feature_url")
  echo "Feature key: $feature_key"

  # Fetch feature details
  feature_response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
    "https://$JIRA_DOMAIN/rest/api/3/issue/$feature_key?fields=description")
  echo "Feature response: $feature_response"

  feature_description=$(echo "$feature_response" | jq -r '.fields.description | @text')
  echo "Feature description: $feature_description"

  # Summarize feature description using Gemini AI
  echo "Summarizing feature description using Gemini AI..."
  prompt_message="You are an intelligent assistant. Summarize the following Jira feature acceptance criteria into a simple, crisp, and clear format suitable for leadership. Focus on the key outcomes and high-level objectives, avoiding technical details or jargon.\n\nAcceptance Criteria:\n\n${feature_description}"  escaped_prompt_message=$(echo "$prompt_message" | jq -sRr @json)
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
  echo "Summary response: $summary_response"

  feature_summary=$(echo "$summary_response" | jq -r '.candidates[0].content.parts[0].text')
  echo "Feature summary: $feature_summary"

  # Store the feature description and summary
  feature_descriptions["$feature_url"]="$feature_summary"
done

# Display the results
echo "Generating HTML table..."
html_table="<table border='1'><tr><th>Feature</th><th>Summary</th><th>Completion Percentage</th></tr>"
for feature_url in "${!feature_map[@]}"; do
  total_stories=${feature_map["$feature_url"]}
  done_stories=${feature_status_count["$feature_url"]}
  completion_percentage=$((100 * done_stories / total_stories))
  feature_summary=${feature_descriptions["$feature_url"]}
  echo "Feature: $feature_url, Completion: $completion_percentage%, Summary: $feature_summary"
  html_table="${html_table}<tr><td>${feature_url}</td><td>${feature_summary}</td><td>${completion_percentage}%</td></tr>"
done
html_table="${html_table}</table>"

# Escape special characters in the HTML table
escaped_html_table=$(echo "$html_table" | sed 's/[\*]/\\*/g' | sed 's/[\_]/\\_/g')

echo escaped_html_table
# Export the escaped HTML table to the GitHub environment
echo "Exporting HTML table to GitHub environment..."
echo "html_table=$escaped_html_table" >> $GITHUB_ENV
echo "Script execution completed."
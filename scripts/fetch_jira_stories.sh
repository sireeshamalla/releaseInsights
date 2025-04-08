#!/bin/bash
echo "Fetching Jira stories for the given Fix Version..."
# Fetch Jira Stories for the given Fix Version
response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_DOMAIN/rest/agile/1.0/board/$BOARD_ID/issue?jql=issuetype=Story%20AND%20fixVersion=%22$FIX_VERSION%22&fields=description")
echo "Response: $response"  # Debugging line
# Extract story keys and summaries from the response
story_data=$(echo "$response" | jq -r '.issues[] | "\(.key)=\(.fields.description)"')
echo "Story Data: $story_data"  # Debugging line
# Initialize the HTML table
html_table="<table border='1'><tr><th>Story Key</th><th>Description</th></tr>"

# Iterate through each story and add rows to the table
while IFS= read -r story; do
  story_key=$(echo "$story" | cut -d'=' -f1)
  story_description=$(echo "$story" | cut -d'=' -f2)
  html_table="${html_table}<tr><td>${story_key}</td><td>${story_description}</td></tr>"
done <<< "$story_data"

# Close the HTML table
html_table="${html_table}</table>"

# Export the HTML table to the GitHub environment
echo "html_table=$html_table" >> $GITHUB_ENV
echo "::set-output name=html_table::$html_table"
# Print the HTML table for debugging
echo "HTML Table: $html_table"
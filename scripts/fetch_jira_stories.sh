#!/bin/bash
echo "Fetching Jira stories for the given Fix Version..."
echo "BOARD_ID: $BOARD_ID"
echo "FIX_VERSION: $FIX_VERSION"
echo "JIRA_DOMAIN: $JIRA_DOMAIN"
echo "JIRA_EMAIL: $JIRA_EMAIL"
echo "JIRA_API_TOKEN: $JIRA_API_TOKEN"
# Fetch Jira Stories for the given Fix Version
response=$(curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_DOMAIN/rest/agile/1.0/board/$BOARD_ID/issue?jql=issuetype=Story%20AND%20fixVersion=%22$FIX_VERSION%22&fields=summary")
echo "Response: $response"  # Debugging line
# Extract story keys and summaries from the response
story_data=$(echo "$response" | jq -r '.issues[] | "\(.key)=\(.fields.summary)"')

# Initialize a variable to store the formatted data
story_list=""

# Iterate through each story and format it
while IFS= read -r story; do
  story_list+="$story;"
done <<< "$story_data"

# Remove the trailing semicolon
story_list=${story_list%;}

# Export the story list to the GitHub environment
echo "story_list=$story_list" >> $GITHUB_ENV

# Print the story list for debugging
echo "Story List: $story_list"
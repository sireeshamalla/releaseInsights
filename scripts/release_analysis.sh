#!/bin/bash

# GitHub API token
GITHUB_TOKEN=${{ secrets.GITHUB_TOKEN }}
REPO_OWNER="your-repo-owner"
REPO_NAME="your-repo-name"

# Get all branches
branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches" | jq -r '.[].name')

# Sort branches and get the latest 2 releases
latest_branches=$(echo "$branches" | grep 'release/' | sort -r | head -n 2)

# Get the latest release branch
latest_release=$(echo "$latest_branches" | head -n 1)
previous_release=$(echo "$latest_branches" | tail -n 1)

# Get the list of changed files between the latest and previous release
changed_files=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/compare/$previous_release...$latest_release" | jq -r '.files[].filename')

# Initialize summary map
declare -A summary_map

# Iterate through each changed file and get the summary
for file in $changed_files; do
  file_diff=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits?path=$file" | jq -r '.[0].commit.message')

  # Call Gemini AI to get the summary of the changes
  summary=$(curl -s -X POST -H "Content-Type: application/json" \
    -d "{\"codeDiff\": \"$file_diff\"}" \
    "https://gemini-ai-api-url/summarize")

  # Save summary in the map
  summary_map["$file"]="$summary"
done

# Create a string using string builder
summary_string=""
for file in "${!summary_map[@]}"; do
  summary_string+="File: $file\nSummary: ${summary_map[$file]}\n\n"
done

# Output the summary for GitHub Actions
echo "::set-output name=summary::$summary_string"
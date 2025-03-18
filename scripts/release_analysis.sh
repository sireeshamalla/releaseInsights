#!/bin/bash

# Enable debug mode
set -x

# GitHub API token
REPO_OWNER="sireeshamalla"
REPO_NAME="releaseInsights"

echo "Fetching all branches..."
# Get all branches
branches=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches" | jq -r '.[].name')

echo "Branches fetched: $branches"

# Sort branches and get the latest 2 releases
latest_branches=$(echo "$branches" | grep 'release-' | sort -r | head -n 2)
echo "Latest branches: $latest_branches"

# Get the latest release branch
latest_release=$(echo "$latest_branches" | head -n 1)
previous_release=$(echo "$latest_branches" | tail -n 1)
echo "Latest release: $latest_release"
echo "Previous release: $previous_release"

echo "Fetching changed files..."
# Get the comparison between the latest and previous release
compare_url="https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/compare/$previous_release...$latest_release"
compare_response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "$compare_url")
changed_files=$(echo "$compare_response" | jq -r '.files[].filename')

echo "Changed files: $changed_files"

# Initialize summary map
declare -A summary_map

# Iterate through each changed file and get the summary
for file in $changed_files; do
  echo "Processing file: $file"
  patch=$(echo "$compare_response" | jq -r --arg file "$file" '.files[] | select(.filename == $file) | .patch')

  if [ -n "$patch" ]; then
    # Create a detailed prompt message
    prompt_message="You are an intelligent code analysis assistant. Your task is to generate a concise summary of the provided code difference (diff) for a file.\n\nInstructions:\n1. Analyze the provided code diff and identify the key changes.\n2. Summarize the changes in a clear and concise manner.\n3. Focus on the most significant modifications, additions, and deletions.\n4. Ensure the summary is easy to understand and provides a high-level overview of the changes.\n\nOutput Format:- [Summary of the key changes in the code diff]\n\nNote: Always prioritize clarity and conciseness.\n\n$patch\"}"
    # Call Gemini AI to get the summary of the changes
    summary=$(curl -s -X POST -H "Content-Type: application/json" \
      -d "{\"prompt\": \"$prompt_message\"}" \
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-001:generateContent??key=$GOOGLE_API_KEY")

    echo "Summary: $summary"

  # Save summary in the map
    summary_map["$file"]="$summary"
  fi
done

# Create a string using string builder
summary_string=""
for file in "${!summary_map[@]}"; do
  summary_string+="File: $file\nSummary: ${summary_map[$file]}\n\n"
done

# Output the summary for GitHub Actions using Environment Files
echo "summary<<EOF" >> $GITHUB_ENV
echo -e "$summary_string" >> $GITHUB_ENV
echo "EOF" >> $GITHUB_ENV

# Disable debug mode
set +x
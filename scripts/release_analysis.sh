#!/bin/bash

# Enable debug mode
set -x

# Check if GEMINI_API_KEY is set
if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY is not set."
  exit 1
fi

# GitHub API token
REPO_OWNER="sireeshamalla"
REPO_NAME="releaseInsights"

echo "Fetching all branches..."
# Get all branches with pagination
PER_PAGE=100
PAGE=1
branches=()

while :; do
  response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches?per_page=$PER_PAGE&page=$PAGE")

  # Extract branch names
  branch_names=$(echo "$response" | jq -r '.[].name')

  # Break the loop if no more branches are returned
  if [ -z "$branch_names" ]; then
    break
  fi

  # Append branch names to the array
  branches+=($branch_names)

  # Increment the page number
  PAGE=$((PAGE + 1))
done

echo "Branches fetched: ${branches[@]}"

# Fetch branch names along with their creation dates
branch_dates=()
for branch in "${branches[@]}"; do
  commit_sha=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches/$branch" | jq -r '.commit.sha')

  commit_date=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/commits/$commit_sha" | jq -r '.commit.committer.date')

  branch_dates+=("$branch|$commit_date")
done

# Sort branches by creation date in descending order
sorted_branches=$(printf "%s\n" "${branch_dates[@]}" | sort -t '|' -k2 -r)

# Extract the latest and previous release branches
latest_branches=$(echo "$sorted_branches" | grep 'release-' | cut -d'|' -f1 | head -n 2)
latest_release=$(echo "$latest_branches" | head -n 1)
previous_release="release-25.98"
#$(echo "$latest_branches" | tail -n 1)

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
    prompt_message="You are an intelligent code analysis assistant. Your task is to generate a concise summary of the key code changes from the provided code difference (diff) for a file.\n\nInstructions:\n1. Analyze the provided code diff and identify the key code changes.\n2. Categorize the changes into two sections: Business Changes and Technical Changes.\n3. Provide a simple and clear list of changes under each section without any explanations or reasons.\n\nOutput Format:\nBusiness Changes:\n- [List of business changes]\n\nTechnical Changes:\n- [List of technical changes]\n\n$patch\"}"
    # Properly escape the prompt_message for JSON    # Properly escape the prompt_message for JSON    # Properly escape the prompt_message for JSON    # Properly escape the prompt_message for JSON
    escaped_prompt_message=$(echo "$prompt_message" | jq -sRr @json)

    # Call Gemini AI to get the summary of the changes
    summary=$(curl \
                -X POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY} \
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

    echo "Summary: $summary"
    text=$(echo "$summary" | jq -r '.candidates[0].content.parts[0].text')

    # Save summary in the map
    summary_map[$file]=$text
  fi
done

echo "latest_branch=$latest_release" >> $GITHUB_ENV
# Output the summary for GitHub Actions using Environment Files
for file in "${!summary_map[@]}"; do
  # Replace any newlines in the summary with a space to ensure a single-line value
  sanitized_summary=$(echo "${summary_map[$file]}" | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "summary_map_${file}=${sanitized_summary}" >> $GITHUB_ENV
done

# Disable debug mode
set +x
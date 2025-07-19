#!/bin/bash
# scripts/karate_feature_testcase_status.sh

echo "[DEBUG] Starting script execution..."

FEATURE_TESTCASEIDS_ENV="${feature_html_table}" # Or use $html_table if exported
echo "[DEBUG] FEATURE_TESTCASEIDS_ENV: $FEATURE_TESTCASEIDS_ENV"

KARATE_REPORT_PATH="target/karate-reports/karate-summary.json"
echo "[DEBUG] KARATE_REPORT_PATH: $KARATE_REPORT_PATH"

# Parse Karate summary report
declare -A karate_passed
declare -A karate_failed

features=$(jq -c '.features[]' "$KARATE_REPORT_PATH")
echo "[DEBUG] Parsed features from Karate report."

while IFS= read -r feature; do
  feature_name=$(echo "$feature" | jq -r '.name')
  echo "[DEBUG] Processing feature: $feature_name"
  while IFS= read -r scenario; do
    testcaseid=$(echo "$scenario" | jq -r '.testCaseId')
    status=$(echo "$scenario" | jq -r '.status')
    echo "[DEBUG] Scenario TestCaseId: $testcaseid, Status: $status"
    if [[ "$status" == "passed" ]]; then
      karate_passed["$feature_name"]+="$testcaseid,"
    elif [[ "$status" == "failed" ]]; then
      karate_failed["$feature_name"]+="$testcaseid,"
    fi
  done < <(echo "$feature" | jq -c '.scenarios[]')
done <<< "$features"

echo "[DEBUG] Finished parsing Karate summary report."
echo "[DEBUG] karate_passed: ${karate_passed[@]}"
echo "[DEBUG] karate_failed: ${karate_failed[@]}"

# Parse feature test case IDs from env variable (HTML table)
summary_table="<table border='1'><tr><th>Feature</th><th>All TestCaseIds</th><th>Passed</th><th>Failed</th><th>Not Ran</th></tr>"
echo "[DEBUG] Generating summary table..."

mapfile -t rows < <(echo "$FEATURE_TESTCASEIDS_ENV" | grep -oP '<tr><td>.*?</td><td>.*?</td><td>.*?</td><td>.*?</td></tr>' )
  for row in "${rows[@]}"; do
    echo "[DEBUG] Processing row: $row"
    feature=$(echo "$row" | sed -n 's|<tr><td>\(.*\)</td><td>.*</td><td>.*</td><td>.*</td></tr>|\1|p')
    all_ids=$(echo "$row" | sed -n 's|<tr><td>.*</td><td>.*</td><td>.*</td><td>\(.*\)</td></tr>|\1|p')
    echo "[DEBUG] Feature: $feature, All TestCaseIds: $all_ids"
    IFS=',' read -ra ids <<< "$all_ids"
    passed_ids=""
    failed_ids=""
    not_ran_ids=""

    # Collect all passed and failed TestCaseIds globally
    all_passed_ids=$(IFS=,; echo "${karate_passed[@]}")
    all_failed_ids=$(IFS=,; echo "${karate_failed[@]}")

    for id in "${ids[@]}"; do
      clean_id="${id#@}"  # Remove leading @
      if [[ ",$all_passed_ids," == *",$clean_id,"* ]]; then
        passed_ids+="$id,"
      elif [[ ",$all_failed_ids," == *",$clean_id,"* ]]; then
        failed_ids+="$id,"
      else
        not_ran_ids+="$id,"
      fi
    done
    echo "[DEBUG] Passed: $passed_ids, Failed: $failed_ids, Not Ran: $not_ran_ids"
    passed_ids="${passed_ids%,}"
    failed_ids="${failed_ids%,}"
    not_ran_ids="${not_ran_ids%,}"
    echo "[DEBUG] After trimming commas, feature:$feature, Passed: $passed_ids, Failed: $failed_ids, Not Ran: $not_ran_ids"
    summary_table="${summary_table}<tr><td>${feature}</td><td>${all_ids}</td><td>${passed_ids}</td><td>${failed_ids}</td><td>${not_ran_ids}</td></tr>"
    echo "[DEBUG] inside loop Final summary_table: $summary_table"
  done

summary_table="${summary_table}</table>"

echo "[DEBUG] Final summary_table: $summary_table"

# Export for email
escaped_summary_table=$(echo "$summary_table" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
echo "[DEBUG] Escaped summary table for export."
echo "karate_feature_testcase_status_table=$escaped_summary_table" >> $GITHUB_ENV
echo "[DEBUG] Script execution completed."
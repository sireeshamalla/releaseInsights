#!/bin/bash
# scripts/karate_feature_testcase_status.sh

FEATURE_TESTCASEIDS_ENV="${feature_html_table}" # Or use $html_table if exported
KARATE_REPORT_PATH="target/karate-reports/karate-summary.json"

# Parse Karate summary report
declare -A karate_passed
declare -A karate_failed

features=$(jq -c '.features[]' "$KARATE_REPORT_PATH")
while IFS= read -r feature; do
  feature_name=$(echo "$feature" | jq -r '.name')
  while IFS= read -r scenario; do
    testcaseid=$(echo "$scenario" | jq -r '.testCaseId')
    status=$(echo "$scenario" | jq -r '.status')
    if [[ "$status" == "passed" ]]; then
      karate_passed["$feature_name"]+="$testcaseid,"
    elif [[ "$status" == "failed" ]]; then
      karate_failed["$feature_name"]+="$testcaseid,"
    fi
  done < <(echo "$feature" | jq -c '.scenarios[]')
done <<< "$features"

# Parse feature test case IDs from env variable (HTML table)
summary_table="<table border='1'><tr><th>Feature</th><th>All TestCaseIds</th><th>Passed</th><th>Failed</th><th>Not Ran</th></tr>"
echo "$FEATURE_TESTCASEIDS_ENV" | grep -oP '<tr><td>.*?</td><td>.*?</td><td>.*?</td><td>.*?</td></tr>' | while read -r row; do
  feature=$(echo "$row" | sed -n 's|<tr><td>\(.*\)</td><td>.*</td><td>.*</td><td>.*</td></tr>|\1|p')
  all_ids=$(echo "$row" | sed -n 's|<tr><td>.*</td><td>.*</td><td>.*</td><td>\(.*\)</td></tr>|\1|p')
  IFS=',' read -ra ids <<< "$all_ids"
  passed_ids=""
  failed_ids=""
  not_ran_ids=""
  for id in "${ids[@]}"; do
    if [[ ",${karate_passed["$feature"]}" == *",$id,"* ]]; then
      passed_ids+="$id,"
    elif [[ ",${karate_failed["$feature"]}" == *",$id,"* ]]; then
      failed_ids+="$id,"
    else
      not_ran_ids+="$id,"
    fi
  done
  passed_ids="${passed_ids%,}"
  failed_ids="${failed_ids%,}"
  not_ran_ids="${not_ran_ids%,}"
  summary_table="${summary_table}<tr><td>${feature}</td><td>${all_ids}</td><td>${passed_ids}</td><td>${failed_ids}</td><td>${not_ran_ids}</td></tr>"
done
summary_table="${summary_table}</table>"

# Export for email
escaped_summary_table=$(echo "$summary_table" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
echo "karate_feature_testcase_status_table=$escaped_summary_table" >> $GITHUB_ENV
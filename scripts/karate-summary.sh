#!/bin/bash
KARATE_REPORT_PATH="target/karate-reports/karate-summary.json"


total_features=$(jq '.features | length' "$KARATE_REPORT_PATH")
total_scenarios=$(jq '[.features[].scenarios[]] | length' "$KARATE_REPORT_PATH")
passed=$(jq '[.features[].scenarios[] | select(.status=="passed")] | length' "$KARATE_REPORT_PATH")
failed=$(jq '[.features[].scenarios[] | select(.status=="failed")] | length' "$KARATE_REPORT_PATH")

table="<table style='border-collapse:collapse; width:50%;'><tr><th style='border:1px solid #000;'>Total Features</th><th style='border:1px solid #000;'>Total Scenarios</th><th style='border:1px solid #000;'>Passed</th><th style='border:1px solid #000;'>Failed</th></tr><tr><td style='border:1px solid #000;'>$total_features</td><td style='border:1px solid #000;'>$total_scenarios</td><td style='border:1px solid #000;'>$passed</td><td style='border:1px solid #000;'>$failed</td></tr></table>"

# Escape newlines and double quotes for GitHub Actions
escaped_table=$(echo "$table" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
echo "karate_summary_table=$escaped_table" >> $GITHUB_ENV
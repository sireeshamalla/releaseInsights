#!/bin/bash
# scripts/fetch_sonarcloud_metrics.sh

set -e

echo "SONAR_TOKEN: $SONAR_TOKEN"
echo "SONAR_PROJECT_KEY: $SONAR_PROJECT_KEY"
echo "SONAR_HOST_URL: $SONAR_HOST_URL"
echo "METRICS: $METRICS"
echo "SONAR_BRANCH: $SONAR_BRANCH"
response=$(curl -s -u $SONAR_TOKEN: "$SONAR_HOST_URL/api/measures/component?component=$SONAR_PROJECT_KEY&metricKeys=$METRICS&branch=$SONAR_BRANCH")
echo "SonarCloud API response: $response"
coverage=$(echo $response | jq -r '.component.measures[] | select(.metric=="coverage") | .value')
code_smells=$(echo $response | jq -r '.component.measures[] | select(.metric=="code_smells") | .value')
echo "Extracted coverage: $coverage"
echo "Extracted code_smells: $code_smells"
echo "sonar_coverage=$coverage" >> $GITHUB_ENV
echo "sonar_code_smells=$code_smells" >> $GITHUB_ENV


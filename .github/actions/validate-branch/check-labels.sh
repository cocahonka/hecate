#!/bin/bash
set +e

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ ERROR: GITHUB_TOKEN environment variable is required"
  exit 1
fi

if [ -z "$ISSUE_NUMBER" ]; then
  echo "❌ ERROR: ISSUE_NUMBER environment variable is required"
  exit 1
fi

if [ -z "$CATEGORY" ]; then
  echo "❌ ERROR: CATEGORY environment variable is required"
  exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "❌ ERROR: GITHUB_REPOSITORY environment variable is required"
  exit 1
fi

echo "🏷️  Checking if issue labels match branch category..."

labels=$(curl -s \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER" | \
  jq -r '.labels[].name')

echo "🏷️ Issue labels: $labels"
echo "🏷️ Required category: $CATEGORY"

echo "$labels" | grep -iq "$CATEGORY"
if [ $? -ne 0 ]; then
  echo "❌ Issue #$ISSUE_NUMBER missing required label: '$CATEGORY'"
  echo "🔧 Add label: https://github.com/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER"
  exit 1
fi

echo "✅ Category matches issue labels"

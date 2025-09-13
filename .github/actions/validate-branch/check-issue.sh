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

if [ -z "$GITHUB_REPOSITORY" ]; then
  echo "❌ ERROR: GITHUB_REPOSITORY environment variable is required"
  exit 1
fi

echo "🔍 Checking if issue #$ISSUE_NUMBER exists..."

response=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER")

if [ "$response" = "200" ]; then
  echo "✅ Issue #$ISSUE_NUMBER exists"
  
  issue_info=$(curl -s \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUMBER")
  
  issue_title=$(echo "$issue_info" | jq -r '.title')
  issue_state=$(echo "$issue_info" | jq -r '.state')
  issue_assignee=$(echo "$issue_info" | jq -r '.assignee.login // "unassigned"')
  
  echo "📋 Issue details:"
  echo "  Title: $issue_title"
  echo "  State: $issue_state"
  echo "  Assignee: $issue_assignee"
  
  if [ "$issue_state" = "closed" ]; then
    echo "⚠️  Warning: Issue #$ISSUE_NUMBER is closed"
    echo "Consider reopening the issue or using a different issue number"
  fi
  
elif [ "$response" = "404" ]; then
  echo "❌ Issue #$ISSUE_NUMBER does not exist!"
  echo ""
  echo "🔗 Create issue first:"
  echo "  https://github.com/$GITHUB_REPOSITORY/issues/new"
  echo ""
  echo "📝 Or use existing issue number from:"
  echo "  https://github.com/$GITHUB_REPOSITORY/issues"
  exit 1
else
  echo "❌ Failed to check issue (HTTP $response)"
  echo "This might be a temporary GitHub API issue"
  exit 1
fi

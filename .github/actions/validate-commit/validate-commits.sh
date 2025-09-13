#!/bin/bash
set +e

SCRIPT_DIR="$(dirname "$0")"
COMMON_SH="$SCRIPT_DIR/../../../scripts/common.sh"

if [ ! -f "$COMMON_SH" ]; then
  echo "❌ ERROR: $COMMON_SH not found"
  exit 1
fi

source "$COMMON_SH"
enable_hook_log

if [ -n "$1" ]; then
  branch_name="$1"
elif [ -n "$GITHUB_HEAD_REF" ]; then
  branch_name="$GITHUB_HEAD_REF"
elif [ -n "$GITHUB_REF_NAME" ]; then
  branch_name="$GITHUB_REF_NAME"
else
  err "❌ ERROR: Could not determine current branch"
  exit 1
fi

log "🌿 Validating commits on branch: $branch_name"

if is_system_branch "$branch_name"; then
  log_is_system_branch
  exit 0
fi

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  log "📋 Pull Request mode: validating all commits in PR"
  if [ -z "$GITHUB_BASE_SHA" ] || [ -z "$GITHUB_HEAD_SHA" ]; then
    err "❌ ERROR: Missing PR commit range information"
    exit 1
  fi
  COMMITS=$(git rev-list --reverse "$GITHUB_BASE_SHA..$GITHUB_HEAD_SHA")
else
  log "📋 Push mode: validating only the latest commit"
  COMMITS=$(git rev-list --reverse HEAD~1..HEAD)
fi

if [ -z "$COMMITS" ]; then
  log "✅ No commits to validate"
  exit 0
fi

log "🌿 Current branch: $current_branch"

VALID_COUNT=0
TOTAL_COUNT=0

for commit_sha in $COMMITS; do
  TOTAL_COUNT=$((TOTAL_COUNT + 1))
  commit_msg=$(git log --format=%s -n 1 "$commit_sha")
  commit_short=$(echo "$commit_sha" | cut -c1-8)
  
  log "Checking commit: $commit_short"
  log "Message: $commit_msg"
  
  usecase_is_commit_message_valid "$commit_msg" "$branch_name"
  result=$?
  
  case $result in
    0)
      log_commit_validation_success "$commit_msg" "$commit_sha"
      VALID_COUNT=$((VALID_COUNT + 1))
      ;;
    1)
      err "❌ ERROR: Commit needs prefix"
      parse_branch_name "$branch_name"
      parse_result=$?
      if [ $parse_result -eq 0 ]; then
        expected_prefix="$branch_category #$branch_issue:"
      else
        expected_prefix="<category> #<issue>:"
      fi
      err "   Expected format: $expected_prefix <message>"
      err "   Suggested fix: $expected_prefix $commit_msg"
      ;;
    2)
      log_commit_empty
      ;;
    3)
      log_branch_invalid_format
      ;;
    4)
      log_branch_empty
      ;;
    5)
      log_branch_invalid_description "$branch_description"
      ;;
    6)
      log_commit_category_mismatch "$commit_category" "$branch_category"
      ;;
    7)
      log_commit_issue_mismatch "$commit_issue" "$branch_issue"
      ;;
    *)
      log_unknown_error_code "$result"
      ;;
  esac
  log ""
done

log ""
log "Validation Summary:"
log "Total commits: $TOTAL_COUNT"
log "Valid commits: $VALID_COUNT"

if [ $VALID_COUNT -eq $TOTAL_COUNT ]; then
  log "✅ All commits are valid"
  exit 0
else
  err "❌ Some commits are invalid"
  err ""
  log_commit_naming_rules
  exit 1
fi

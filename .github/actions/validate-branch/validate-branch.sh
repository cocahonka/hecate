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

log "🌿 Branch: $branch_name"

if is_system_branch "$branch_name"; then
  log_is_system_branch
  echo "VALID_FORMAT=system"
  exit 0
fi

usecase_is_branch_format_valid "$branch_name"
result=$?

if [ $result -eq 0 ]; then
  echo "CATEGORY=$branch_category"
  echo "ISSUE_NUMBER=$branch_issue"
  echo "VALID_FORMAT=true"
  log_branch_validation_success
else
  echo "VALID_FORMAT=false"
  case $result in
    1)
      log_branch_invalid_format
      ;;
    2)
      log_branch_empty
      ;;
    3)
      log_branch_invalid_description "$branch_description"
      ;;
    *)
      log_unknown_error_code "$result"
      ;;
  esac
  err ""
  log_branch_naming_rules
  exit 1
fi

#!/bin/sh
set +e

ALLOWED_CATEGORIES="frontend backend junk"
SYSTEM_BRANCHES="trunk main master"
BRANCH_REGEX="^(frontend|backend|junk)/#([0-9]+)/(.+)$"
COMMIT_REGEX="^(frontend|backend|junk) #([0-9]+): (.+)$"
BRANCH_DESCRIPTION_REGEX="^[a-z0-9/_-]+$"

HOOK_LOG=$(git config --get hook.log 2>/dev/null || echo "false")

log() {
    if [ "$HOOK_LOG" = "true" ]; then
        echo "$1"
    fi
}

err() {
    echo "$1" >&2
}

enable_hook_log() {
    HOOK_LOG="true"
    git config --global hook.log true 2>/dev/null || true
}

disable_hook_log() {
    HOOK_LOG="false"
    git config --global hook.log false 2>/dev/null || true
}

get_current_branch() {
    git branch --show-current 2>/dev/null
}

is_system_branch() {
    local branch_name="$1"
    local system_branch
    
    for system_branch in $SYSTEM_BRANCHES; do
        if [ "$branch_name" = "$system_branch" ]; then
            return 0
        fi
    done
    
    return 1
}

# 2 - empty
parse_branch_name() {
    local branch_name="$1"
    branch_category=""
    branch_issue=""
    branch_description=""
    
    if [ -z "$branch_name" ]; then
        return 2
    fi
    
    if [[ "$branch_name" =~ $BRANCH_REGEX ]]; then
        branch_category="${BASH_REMATCH[1]}"
        branch_issue="${BASH_REMATCH[2]}"
        branch_description="${BASH_REMATCH[3]}"
        return 0
    fi
    
    return 1
}

is_branch_description_valid() {
    local description="$1"
    
    if [[ ! "$description" =~ $BRANCH_DESCRIPTION_REGEX ]]; then
        return 1
    fi
    
    return 0
}

# 2 - empty
# 3 - invalid characters in branch description
usecase_is_branch_format_valid() {
    local branch_name="$1"
    
    parse_branch_name "$branch_name"
    local parse_result=$?
    
    if [ $parse_result -eq 2 ]; then
        return 2
    elif [ $parse_result -eq 1 ]; then
        return 1
    fi
    
    if ! is_branch_description_valid "$branch_description"; then
        return 3
    fi
    
    return 0
}

# 2 - empty
parse_commit_message() {
    local commit_msg="$1"
    commit_category=""
    commit_issue=""
    commit_message=""
    
    if [ -z "$commit_msg" ]; then
        return 2
    fi
    
    if [[ "$commit_msg" =~ $COMMIT_REGEX ]]; then
        commit_category="${BASH_REMATCH[1]}"
        commit_issue="${BASH_REMATCH[2]}"
        commit_message="${BASH_REMATCH[3]}"
        return 0
    fi
    
    return 1
}

# 2 - empty
# 3 - branch invalid format
# 4 - branch empty
# 5 - branch invalid characters in description
# 6 - commit category mismatch
# 7 - commit issue mismatch
usecase_is_commit_message_valid() {
    local commit_msg="$1"
    local branch_name="$2"
    
    usecase_is_branch_format_valid "$branch_name"
    local branch_format_result=$?

    if [ $branch_format_result -eq 1 ]; then
        return 3
    elif [ $branch_format_result -eq 2 ]; then
        return 4
    elif [ $branch_format_result -eq 3 ]; then
        return 5
    fi

    parse_commit_message "$commit_msg"
    local commit_parse_result=$?
    
    if [ $commit_parse_result -eq 2 ]; then
        return 2
    elif [ $commit_parse_result -eq 1 ]; then
        return 1
    fi

    if [ "$commit_category" != "$branch_category" ]; then
        return 6
    fi

    if [ "$commit_issue" != "$branch_issue" ]; then
        return 7
    fi
    
    return 0
}

log_branch_naming_rules() {
    err "📋 Required branch format:"
    err "   <category>/#<issue>/<description>"
    err ""
    err "✅ Valid branch examples:"
    err "   frontend/#24/user-login"
    err "   backend/#32/api-endpoint/user-management"
    err ""
    err "📝 Rules:"
    err "   • Category: $ALLOWED_CATEGORIES"
    err "   • Issue: #123 (hash + number)"
    err "   • Description: lowercase, hyphens, underscores, slashes allowed"
}

log_branch_invalid_format() {
    local branch_name="$1"
    err "❌ ERROR: Invalid branch format"
    if [ -n "$branch_name" ]; then
        err "   Current branch: $branch_name"
    fi
}

log_branch_empty() {
    err "❌ ERROR: Empty branch name"
}

log_branch_invalid_description() {
    local description="$1"
    local branch_name="$2"
    err "❌ ERROR: Invalid characters in branch description"
    if [ -n "$description" ]; then
        err "   Current description: $description"
    fi
    if [ -n "$branch_name" ]; then
        err "   Current branch: $branch_name"
    fi
}

log_branch_validation_success() {
    local branch_name="$1"
    if [ -n "$branch_name" ]; then
        log "✅ Branch format validation passed for '$branch_name'"
    else
        log "✅ Branch format validation passed"
    fi
}

log_commit_naming_rules() {
    err "📋 Required commit format:"
    err "   <category> #<issue>: <message>"
    err ""
    err "✅ Valid commit examples:"
    err "   frontend #24: add user login form"
    err "   backend #32: implement API endpoint/user-management"
    err ""
    err "📝 Rules:"
    err "   • Category: $ALLOWED_CATEGORIES"
    err "   • Issue: #123 (hash + number)"
    err "   • Message: any text describing the change"
}

log_commit_invalid_format() {
    local commit_msg="$1"
    err "❌ ERROR: Invalid commit message format"
    if [ -n "$commit_msg" ]; then
        err "   Current commit message: $commit_msg"
    fi
}

log_commit_empty() {
    err "❌ ERROR: Empty commit message"
}

log_commit_category_mismatch() {
    local commit_category="$1"
    local branch_category="$2"
    local branch_name="$3"
    err "❌ ERROR: Commit category mismatch with branch"
    if [ -n "$commit_category" ]; then
        err "   Commit category: $commit_category"
    fi
    if [ -n "$branch_category" ]; then
        err "   Branch category: $branch_category"
    fi
    if [ -n "$branch_name" ]; then
        err "   Current branch: $branch_name"
    fi
    err "📝 Commit and branch category must match"
}

log_commit_issue_mismatch() {
    local commit_issue="$1"
    local branch_issue="$2"
    local branch_name="$3"
    err "❌ ERROR: Commit issue mismatch with branch"
    if [ -n "$commit_issue" ]; then
        err "   Commit issue: $commit_issue"
    fi
    if [ -n "$branch_issue" ]; then
        err "   Branch issue: $branch_issue"
    fi
    if [ -n "$branch_name" ]; then
        err "   Current branch: $branch_name"
    fi
    err "📝 Commit and branch issue must match"
}

log_commit_validation_success() {
    local commit_msg="$1"
    local commit_sha="$2"
    if [ -n "$commit_sha" ] && [ -n "$commit_msg" ]; then
        log "✅ Commit validation passed: $(echo "$commit_sha" | cut -c1-8) - $commit_msg"
    elif [ -n "$commit_msg" ]; then
        log "✅ Commit validation passed: $commit_msg"
    elif [ -n "$commit_sha" ]; then
        log "✅ Commit validation passed: $(echo "$commit_sha" | cut -c1-8)"
    else
        log "✅ Commit message validation passed"
    fi
}

log_is_system_branch() {
    local branch_name="$1"
    if [ -n "$branch_name" ]; then
        log "✅ System branch '$branch_name' detected, skipping validation"
    else
        log "✅ System branch detected, skipping validation"
    fi
}

log_unknown_error_code() {
    local error_code="$1"
    err "❌ ERROR: Unknown validation error (code: $error_code)"
}
    
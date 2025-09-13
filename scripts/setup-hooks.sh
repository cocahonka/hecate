#!/bin/bash
set +e

echo "🛠️  Git Hooks Setup Script"
echo "========================="

if [ ! -d .git ]; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

if [ ! -d .githooks ]; then
    echo "❌ Error: .githooks directory not found"
    exit 1
fi

echo "📂 Repository: $(pwd)"
echo ""

read -p "🤔 Enable git hooks? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🔧 Configuring git hooks..."
    git config core.hooksPath .githooks
    echo "✅ Configured git to use .githooks directory"
    echo ""
else
    echo "🔧 Disabling git hooks..."
    git config --unset core.hooksPath 2>/dev/null || true
    echo "✅ Git hooks disabled - using default git behavior"
    echo ""
    exit 0
fi

echo "🔐 Setting up hook permissions..."

ALLOWED_HOOKS=(
    "pre-commit" 
    "commit-msg" 
    "post-commit" 
    "pre-push" 
    "post-merge" 
    "pre-rebase" 
    "post-checkout"
    "prepare-commit-msg"
    "applypatch-msg"
    "pre-applypatch"
    "post-applypatch"
    "pre-receive"
    "update"
    "post-receive"
    "post-update"
    "push-to-checkout"
    "pre-auto-gc"
    "post-rewrite"
    "sendemail-validate"
)

hooks_activated=0

for hook_name in "${ALLOWED_HOOKS[@]}"; do
    hook_file=".githooks/$hook_name"
    
    if [ -f "$hook_file" ]; then
        if head -n1 "$hook_file" 2>/dev/null | grep -q "^#!/"; then
            chmod +x "$hook_file"
            echo "  ✅ $hook_name"
            hooks_activated=$((hooks_activated + 1))
        else
            echo "  ⚠️  $hook_name (invalid format, skipped)"
        fi
    fi
done

if [ $hooks_activated -eq 0 ]; then
    echo "❌ No valid hooks found in .githooks/"
    exit 1
fi

echo "📊 Activated $hooks_activated hooks"

echo ""
echo "📝 Hook logging configuration"
echo "-----------------------------"

current_log=$(git config --get hook.log 2>/dev/null || echo "false")
echo "Current setting: $current_log"
echo ""
echo "Logging options:"
echo "  🔇 false - Minimal output"
echo "  🔊 true  - Detailed hook output"
echo ""

read -p "🤔 Enable detailed hook logging? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git config hook.log true
    echo "✅ Detailed logging enabled"
else
    git config hook.log false
    echo "✅ Minimal logging enabled (default)"
fi

echo ""
echo "🔍 Final Configuration"
echo "----------------------"
echo "📂 Hooks directory: .githooks"
echo "🎣 Active hooks: $hooks_activated"
echo "📝 Logging: $(git config --get hook.log)"

echo ""
echo "🎉 Git hooks setup completed!"
echo ""
echo "💡 Notes:"
echo "  • Hooks are now active for this repository"
echo "  • You can run this script again to reconfigure"
echo "  • Use 'git config hook.log true/false' to toggle logging"
echo ""
echo "🔗 Repository-specific hook configuration is ready"

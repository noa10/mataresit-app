#!/bin/bash

# Script to set up a pre-commit hook that checks formatting before commits
# This helps prevent CI/CD failures due to formatting issues

set -e

HOOK_FILE=".git/hooks/pre-commit"

echo "🔧 Setting up pre-commit hook for formatting checks..."

# Create the pre-commit hook
cat > "$HOOK_FILE" << 'EOF'
#!/bin/bash

# Pre-commit hook to check Dart formatting
# This prevents commits with formatting issues that would fail CI/CD

echo "🔍 Checking Dart code formatting before commit..."

# Check if dart format would make any changes
if ! dart format --set-exit-if-changed . > /dev/null 2>&1; then
    echo "❌ Code formatting check failed!"
    echo ""
    echo "Some files need formatting. Please run:"
    echo "  dart format ."
    echo ""
    echo "Then stage your changes and commit again."
    exit 1
fi

echo "✅ Code formatting check passed!"
EOF

# Make the hook executable
chmod +x "$HOOK_FILE"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "Now, every time you commit, the formatting will be checked automatically."
echo "If formatting issues are found, the commit will be blocked until you fix them."
echo ""
echo "To bypass the hook (not recommended), use: git commit --no-verify"

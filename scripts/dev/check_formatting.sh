#!/bin/bash

# Script to check code formatting before pushing to avoid CI/CD failures
# This script runs the same formatting checks as the GitHub Actions workflow

set -e

echo "🔍 Checking Dart code formatting..."

# Check if dart format would make any changes
if dart format --set-exit-if-changed .; then
    echo "✅ All files are properly formatted!"
    exit 0
else
    echo "❌ Some files need formatting. Run 'dart format .' to fix them."
    echo ""
    echo "💡 To automatically format all files, run:"
    echo "   dart format ."
    echo ""
    echo "🔧 To check which files need formatting without changing them:"
    echo "   dart format --dry-run ."
    exit 1
fi

# Code Formatting Guide

This document explains the code formatting standards and tools used in the Mataresit app project.

## Overview

The project uses Dart's built-in formatter to ensure consistent code style across all files. The CI/CD pipeline automatically checks formatting and will fail if any files don't conform to the standard.

## Formatting Standards

- **Tool**: `dart format` (built into Dart SDK)
- **Style**: Official Dart formatting guidelines
- **Enforcement**: Automatic checks in GitHub Actions CI/CD pipeline

## Local Development

### Check Formatting

To check if your code is properly formatted without making changes:

```bash
# Check all files
dart format --dry-run .

# Check specific file
dart format --dry-run lib/main.dart
```

### Apply Formatting

To automatically format all files:

```bash
# Format all files
dart format .

# Format specific file
dart format lib/main.dart
```

### Verify CI/CD Compatibility

To run the same check that the CI/CD pipeline uses:

```bash
# This will exit with code 1 if formatting is needed
dart format --set-exit-if-changed .

# Or use our helper script
./scripts/check_formatting.sh
```

## Automation Tools

### Pre-commit Hook

Set up a pre-commit hook to automatically check formatting before each commit:

```bash
./scripts/setup_pre_commit_hook.sh
```

This will prevent commits with formatting issues, helping you catch problems before they reach the CI/CD pipeline.

### IDE Integration

Most IDEs support automatic Dart formatting:

- **VS Code**: Install the Dart extension and enable "Format on Save"
- **Android Studio/IntelliJ**: Enable "Reformat code" in commit options
- **Vim/Neovim**: Use dart-vim-plugin with format-on-save

## CI/CD Pipeline

The GitHub Actions workflow includes a formatting check step:

```yaml
- name: Check formatting
  run: dart format --set-exit-if-changed .
```

If this step fails:
1. The entire CI/CD pipeline will fail
2. You'll need to run `dart format .` locally
3. Commit and push the formatting changes

## Troubleshooting

### Common Issues

**Problem**: CI/CD fails with "Process completed with exit code 1" on formatting check

**Solution**: 
```bash
# Apply formatting locally
dart format .

# Commit the changes
git add .
git commit -m "fix: apply dart format to resolve formatting issues"
git push
```

**Problem**: Pre-commit hook blocks your commit

**Solution**:
```bash
# Fix formatting
dart format .

# Stage the formatted files
git add .

# Commit again
git commit -m "your commit message"
```

### Bypassing Checks (Not Recommended)

If you absolutely need to bypass formatting checks:

```bash
# Skip pre-commit hook
git commit --no-verify

# Note: This will still fail in CI/CD
```

## Best Practices

1. **Format before committing**: Always run `dart format .` before committing
2. **Use IDE integration**: Enable format-on-save in your IDE
3. **Set up pre-commit hook**: Use the provided script to catch issues early
4. **Check CI/CD status**: Monitor GitHub Actions for any formatting failures

## Related Files

- `scripts/check_formatting.sh` - Local formatting check script
- `scripts/setup_pre_commit_hook.sh` - Pre-commit hook setup script
- `.github/workflows/ci-cd.yml` - CI/CD pipeline configuration

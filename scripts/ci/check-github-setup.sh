#!/bin/bash

# GitHub Repository Setup Checker
# This script helps verify GitHub repository configuration for CI/CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_header "GITHUB REPOSITORY SETUP CHECKER"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository"
    exit 1
fi

# Get repository information
REPO_URL=$(git config --get remote.origin.url)
print_status "Repository URL: $REPO_URL"

# Check if GitHub CLI is available
if command -v gh &> /dev/null; then
    print_success "GitHub CLI is available"
    
    # Check authentication
    if gh auth status > /dev/null 2>&1; then
        print_success "GitHub CLI is authenticated"
        
        # Get repository info
        REPO_INFO=$(gh repo view --json name,owner,isPrivate,hasActionsEnabled 2>/dev/null || echo "{}")
        
        if [ "$REPO_INFO" != "{}" ]; then
            REPO_NAME=$(echo "$REPO_INFO" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
            OWNER=$(echo "$REPO_INFO" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
            IS_PRIVATE=$(echo "$REPO_INFO" | grep -o '"isPrivate":[^,}]*' | cut -d':' -f2)
            HAS_ACTIONS=$(echo "$REPO_INFO" | grep -o '"hasActionsEnabled":[^,}]*' | cut -d':' -f2)
            
            print_status "Repository: $OWNER/$REPO_NAME"
            print_status "Private: $IS_PRIVATE"
            print_status "Actions Enabled: $HAS_ACTIONS"
            
            if [ "$HAS_ACTIONS" = "false" ]; then
                print_error "GitHub Actions is not enabled for this repository"
                echo "To enable GitHub Actions:"
                echo "1. Go to your repository on GitHub"
                echo "2. Click Settings tab"
                echo "3. Click Actions in the left sidebar"
                echo "4. Select 'Allow all actions and reusable workflows'"
            else
                print_success "GitHub Actions is enabled"
            fi
        else
            print_warning "Could not retrieve repository information"
        fi
        
        # Check secrets
        print_status "Checking GitHub secrets..."
        SECRETS=$(gh secret list 2>/dev/null || echo "")
        
        if [ -n "$SECRETS" ]; then
            print_success "Repository has secrets configured"
            echo "$SECRETS"
        else
            print_warning "No secrets found or unable to list secrets"
        fi
        
    else
        print_warning "GitHub CLI is not authenticated"
        echo "Run: gh auth login"
    fi
else
    print_warning "GitHub CLI is not installed"
    echo "Install from: https://cli.github.com/"
fi

# Check workflow files
print_header "WORKFLOW FILES CHECK"

WORKFLOW_DIR=".github/workflows"
if [ -d "$WORKFLOW_DIR" ]; then
    print_success "Workflows directory exists"
    
    WORKFLOW_FILES=$(find "$WORKFLOW_DIR" -name "*.yml" -o -name "*.yaml")
    if [ -n "$WORKFLOW_FILES" ]; then
        print_success "Found workflow files:"
        echo "$WORKFLOW_FILES" | while read -r file; do
            echo "  - $file"
        done
        
        # Check specific required workflows
        REQUIRED_WORKFLOWS=("ci-cd.yml" "pr-check.yml")
        for workflow in "${REQUIRED_WORKFLOWS[@]}"; do
            if [ -f "$WORKFLOW_DIR/$workflow" ]; then
                print_success "$workflow exists"
            else
                print_error "$workflow is missing"
            fi
        done
    else
        print_error "No workflow files found in $WORKFLOW_DIR"
    fi
else
    print_error "Workflows directory does not exist: $WORKFLOW_DIR"
fi

# Check git status
print_header "GIT STATUS CHECK"

# Check if there are uncommitted changes
if git diff --quiet && git diff --cached --quiet; then
    print_success "Working directory is clean"
else
    print_warning "There are uncommitted changes"
    echo "Uncommitted files:"
    git status --porcelain
fi

# Check if we're on main branch
CURRENT_BRANCH=$(git branch --show-current)
print_status "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" = "main" ]; then
    print_success "On main branch"
else
    print_warning "Not on main branch"
fi

# Check if main branch exists on remote
if git ls-remote --heads origin main | grep -q main; then
    print_success "Main branch exists on remote"
else
    print_warning "Main branch does not exist on remote"
fi

# Check recent commits
print_status "Recent commits:"
git log --oneline -5

print_header "TROUBLESHOOTING STEPS"

echo "If workflows are not appearing in GitHub Actions:"
echo ""
echo "1. **Verify File Location**:"
echo "   - Ensure workflow files are in .github/workflows/ directory"
echo "   - Check file extensions are .yml or .yaml"
echo ""
echo "2. **Check Repository Settings**:"
echo "   - Go to Settings → Actions → General"
echo "   - Ensure 'Allow all actions and reusable workflows' is selected"
echo "   - Check if Actions are enabled for your repository type"
echo ""
echo "3. **Validate YAML Syntax**:"
echo "   - Use online YAML validators"
echo "   - Check indentation (use spaces, not tabs)"
echo "   - Verify all required fields are present"
echo ""
echo "4. **Push Changes**:"
echo "   - Ensure all workflow files are committed and pushed"
echo "   - Check if the push was successful"
echo ""
echo "5. **Branch Protection**:"
echo "   - Workflows may not run if branch protection rules prevent them"
echo "   - Check Settings → Branches for any restrictions"
echo ""
echo "6. **Repository Permissions**:"
echo "   - For organization repositories, check if Actions are allowed"
echo "   - Verify you have the necessary permissions"

print_header "NEXT STEPS"

echo "To test the CI/CD pipeline:"
echo ""
echo "1. **Commit and push workflow files**:"
echo "   git add .github/workflows/"
echo "   git commit -m 'feat: add CI/CD workflows'"
echo "   git push origin main"
echo ""
echo "2. **Create a test pull request**:"
echo "   git checkout -b test-ci-cd"
echo "   echo '# Test' >> README.md"
echo "   git add README.md"
echo "   git commit -m 'test: trigger CI/CD pipeline'"
echo "   git push origin test-ci-cd"
echo "   # Then create PR on GitHub"
echo ""
echo "3. **Monitor workflow execution**:"
echo "   - Go to Actions tab in GitHub"
echo "   - Watch for workflow runs"
echo "   - Check logs for any errors"

print_success "Repository setup check completed!"

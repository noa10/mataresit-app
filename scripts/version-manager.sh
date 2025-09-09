#!/bin/bash

# Mataresit App - Version Management Script
# This script handles version bumping and release management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERSION_TYPE="patch"
DRY_RUN=false
COMMIT_CHANGES=false
CREATE_TAG=false

# Function to print colored output
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

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE        Version bump type: major, minor, patch (default: patch)"
    echo "  -v, --version VERSION  Set specific version (e.g., 1.2.3)"
    echo "  -b, --build BUILD      Set specific build number"
    echo "  --dry-run              Show what would be changed without making changes"
    echo "  --commit               Commit the version changes"
    echo "  --tag                  Create a git tag for the new version"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                     # Bump patch version"
    echo "  $0 -t minor            # Bump minor version"
    echo "  $0 -v 2.0.0            # Set specific version"
    echo "  $0 --dry-run           # Preview changes"
    echo "  $0 --commit --tag      # Bump version, commit, and tag"
}

# Parse command line arguments
SPECIFIC_VERSION=""
SPECIFIC_BUILD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            VERSION_TYPE="$2"
            shift 2
            ;;
        -v|--version)
            SPECIFIC_VERSION="$2"
            shift 2
            ;;
        -b|--build)
            SPECIFIC_BUILD="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --commit)
            COMMIT_CHANGES=true
            shift
            ;;
        --tag)
            CREATE_TAG=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate version type
if [ -z "$SPECIFIC_VERSION" ]; then
    case $VERSION_TYPE in
        major|minor|patch)
            ;;
        *)
            print_error "Invalid version type: $VERSION_TYPE"
            exit 1
            ;;
    esac
fi

print_status "Mataresit App Version Manager"
print_status "Current directory: $(pwd)"

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Are you in the Flutter project root?"
    exit 1
fi

# Get current version from pubspec.yaml
CURRENT_VERSION_LINE=$(grep '^version:' pubspec.yaml)
if [ -z "$CURRENT_VERSION_LINE" ]; then
    print_error "Version not found in pubspec.yaml"
    exit 1
fi

CURRENT_VERSION=$(echo "$CURRENT_VERSION_LINE" | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(echo "$CURRENT_VERSION_LINE" | sed 's/.*+//')

print_status "Current version: $CURRENT_VERSION+$CURRENT_BUILD"

# Calculate new version
if [ -n "$SPECIFIC_VERSION" ]; then
    NEW_VERSION="$SPECIFIC_VERSION"
    print_status "Setting specific version: $NEW_VERSION"
else
    # Parse current version
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}

    # Increment based on type
    case $VERSION_TYPE in
        major)
            MAJOR=$((MAJOR + 1))
            MINOR=0
            PATCH=0
            ;;
        minor)
            MINOR=$((MINOR + 1))
            PATCH=0
            ;;
        patch)
            PATCH=$((PATCH + 1))
            ;;
    esac

    NEW_VERSION="$MAJOR.$MINOR.$PATCH"
    print_status "Bumping $VERSION_TYPE version: $CURRENT_VERSION → $NEW_VERSION"
fi

# Calculate new build number
if [ -n "$SPECIFIC_BUILD" ]; then
    NEW_BUILD="$SPECIFIC_BUILD"
    print_status "Setting specific build number: $NEW_BUILD"
else
    NEW_BUILD=$((CURRENT_BUILD + 1))
    print_status "Incrementing build number: $CURRENT_BUILD → $NEW_BUILD"
fi

NEW_VERSION_STRING="$NEW_VERSION+$NEW_BUILD"
print_status "New version string: $NEW_VERSION_STRING"

# Dry run check
if [ "$DRY_RUN" = true ]; then
    print_warning "DRY RUN MODE - No changes will be made"
    echo ""
    echo "Changes that would be made:"
    echo "  pubspec.yaml: version: $CURRENT_VERSION+$CURRENT_BUILD → version: $NEW_VERSION_STRING"
    
    if [ "$COMMIT_CHANGES" = true ]; then
        echo "  Git commit: 'chore: bump version to $NEW_VERSION_STRING'"
    fi
    
    if [ "$CREATE_TAG" = true ]; then
        echo "  Git tag: 'v$NEW_VERSION'"
    fi
    
    exit 0
fi

# Update pubspec.yaml
print_status "Updating pubspec.yaml..."
if sed -i.bak "s/^version:.*/version: $NEW_VERSION_STRING/" pubspec.yaml; then
    print_success "Updated pubspec.yaml"
    rm pubspec.yaml.bak
else
    print_error "Failed to update pubspec.yaml"
    exit 1
fi

# Verify the change
UPDATED_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
if [ "$UPDATED_VERSION" = "$NEW_VERSION_STRING" ]; then
    print_success "Version successfully updated to $NEW_VERSION_STRING"
else
    print_error "Version update verification failed"
    exit 1
fi

# Update Android version codes if needed
ANDROID_BUILD_FILE="android/app/build.gradle.kts"
if [ -f "$ANDROID_BUILD_FILE" ]; then
    print_status "Android build file found, version will be managed by Flutter"
fi

# Generate changelog entry
CHANGELOG_FILE="CHANGELOG.md"
if [ -f "$CHANGELOG_FILE" ]; then
    print_status "Updating CHANGELOG.md..."
    
    # Create temporary changelog entry
    TEMP_CHANGELOG=$(mktemp)
    echo "## [$NEW_VERSION] - $(date +%Y-%m-%d)" > "$TEMP_CHANGELOG"
    echo "" >> "$TEMP_CHANGELOG"
    echo "### Added" >> "$TEMP_CHANGELOG"
    echo "- New features and improvements" >> "$TEMP_CHANGELOG"
    echo "" >> "$TEMP_CHANGELOG"
    echo "### Changed" >> "$TEMP_CHANGELOG"
    echo "- Updates and modifications" >> "$TEMP_CHANGELOG"
    echo "" >> "$TEMP_CHANGELOG"
    echo "### Fixed" >> "$TEMP_CHANGELOG"
    echo "- Bug fixes and corrections" >> "$TEMP_CHANGELOG"
    echo "" >> "$TEMP_CHANGELOG"
    
    # Prepend to existing changelog
    cat "$CHANGELOG_FILE" >> "$TEMP_CHANGELOG"
    mv "$TEMP_CHANGELOG" "$CHANGELOG_FILE"
    
    print_success "Updated CHANGELOG.md"
else
    print_warning "CHANGELOG.md not found, skipping changelog update"
fi

# Git operations
if [ "$COMMIT_CHANGES" = true ]; then
    print_status "Committing version changes..."
    
    # Check if git is available and we're in a git repo
    if ! command -v git &> /dev/null; then
        print_error "Git is not available"
        exit 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Add files to git
    git add pubspec.yaml
    if [ -f "$CHANGELOG_FILE" ]; then
        git add "$CHANGELOG_FILE"
    fi
    
    # Commit changes
    COMMIT_MESSAGE="chore: bump version to $NEW_VERSION_STRING"
    if git commit -m "$COMMIT_MESSAGE"; then
        print_success "Committed version changes"
    else
        print_error "Failed to commit changes"
        exit 1
    fi
    
    # Create tag if requested
    if [ "$CREATE_TAG" = true ]; then
        print_status "Creating git tag..."
        TAG_NAME="v$NEW_VERSION"
        TAG_MESSAGE="Release version $NEW_VERSION"
        
        if git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"; then
            print_success "Created tag: $TAG_NAME"
        else
            print_error "Failed to create tag"
            exit 1
        fi
    fi
fi

# Summary
echo ""
print_success "Version management completed!"
echo "📋 Summary:"
echo "  Previous version: $CURRENT_VERSION+$CURRENT_BUILD"
echo "  New version: $NEW_VERSION_STRING"
echo "  Version type: $VERSION_TYPE"

if [ "$COMMIT_CHANGES" = true ]; then
    echo "  Git commit: ✅ Created"
    if [ "$CREATE_TAG" = true ]; then
        echo "  Git tag: ✅ Created (v$NEW_VERSION)"
    fi
fi

echo ""
echo "🚀 Next steps:"
echo "  1. Review the changes in pubspec.yaml"
if [ -f "$CHANGELOG_FILE" ]; then
    echo "  2. Update CHANGELOG.md with specific changes"
fi
echo "  3. Test the app with the new version"
echo "  4. Push changes to repository: git push && git push --tags"
echo "  5. Create a release build: flutter build apk --release"

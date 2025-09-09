#!/bin/bash

# Mataresit App - Release Preparation Script
# This script prepares the app for release by running all necessary checks and builds

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SKIP_TESTS=false
SKIP_BUILD=false
VERSION_BUMP="patch"
CREATE_TAG=false
PUSH_CHANGES=false

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
    echo "  -v, --version-bump TYPE  Version bump type: major, minor, patch (default: patch)"
    echo "  --skip-tests             Skip running tests"
    echo "  --skip-build             Skip building the app"
    echo "  --tag                    Create git tag after version bump"
    echo "  --push                   Push changes to remote repository"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                       # Prepare patch release"
    echo "  $0 -v minor              # Prepare minor release"
    echo "  $0 --tag --push          # Prepare release with git tag and push"
    echo "  $0 --skip-tests          # Skip tests (not recommended)"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version-bump)
            VERSION_BUMP="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --tag)
            CREATE_TAG=true
            shift
            ;;
        --push)
            PUSH_CHANGES=true
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

print_status "🚀 Preparing Mataresit App for release..."
print_status "Version bump: $VERSION_BUMP"
print_status "Skip tests: $SKIP_TESTS"
print_status "Skip build: $SKIP_BUILD"
print_status "Create tag: $CREATE_TAG"
print_status "Push changes: $PUSH_CHANGES"

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in a Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Are you in the Flutter project root?"
    exit 1
fi

# Check if git is available (if needed)
if [ "$CREATE_TAG" = true ] || [ "$PUSH_CHANGES" = true ]; then
    if ! command -v git &> /dev/null; then
        print_error "Git is not available but required for tagging/pushing"
        exit 1
    fi
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
fi

print_success "Prerequisites check passed"

# Step 1: Clean and get dependencies
print_status "Step 1: Cleaning and getting dependencies..."
flutter clean
flutter pub get
print_success "Dependencies updated"

# Step 2: Run code analysis
print_status "Step 2: Running code analysis..."
if flutter analyze --no-fatal-infos; then
    print_success "Code analysis passed"
else
    print_error "Code analysis failed"
    exit 1
fi

# Step 3: Check code formatting
print_status "Step 3: Checking code formatting..."
if dart format --set-exit-if-changed .; then
    print_success "Code formatting is correct"
else
    print_warning "Code formatting issues found. Run 'dart format .' to fix them."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 4: Run tests
if [ "$SKIP_TESTS" = false ]; then
    print_status "Step 4: Running tests..."
    
    # Create test environment
    if [ ! -f ".env.test" ]; then
        print_status "Creating test environment file..."
        cat > .env.test << EOF
# Test environment variables
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test_key_12345
SUPABASE_PROJECT_ID=test_project
STRIPE_PUBLIC_KEY=pk_test_dummy_key
GEMINI_API_KEY=test_gemini_api_key
OPENROUTER_API_KEY=test_openrouter_key
AWS_ACCESS_KEY_ID=test_aws_access_key
AWS_SECRET_ACCESS_KEY=test_aws_secret_key
EOF
    fi
    
    if flutter test --coverage; then
        print_success "All tests passed"
        
        # Show coverage summary if available
        if [ -f "coverage/lcov.info" ] && command -v lcov &> /dev/null; then
            COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' | head -1)
            print_status "Code coverage: $COVERAGE_PERCENT"
        fi
    else
        print_error "Tests failed"
        exit 1
    fi
else
    print_warning "Skipping tests (not recommended for release)"
fi

# Step 5: Check environment configuration
print_status "Step 5: Checking environment configuration..."
if [ -f ".env" ]; then
    print_success "Environment file found"
    
    # Check for required variables
    required_vars=("SUPABASE_URL" "SUPABASE_ANON_KEY" "GEMINI_API_KEY")
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env; then
            print_success "$var is configured"
        else
            print_warning "$var is not configured in .env"
        fi
    done
else
    print_error "Environment file (.env) not found"
    exit 1
fi

# Step 6: Check Android signing configuration
print_status "Step 6: Checking Android signing configuration..."
if [ -f "android/key.properties" ]; then
    print_success "Android signing configuration found"
elif [ -f "android/key.properties.template" ]; then
    print_warning "Only template signing configuration found"
    print_warning "For release builds, you need to set up proper signing"
    print_warning "See android/key.properties.template for instructions"
else
    print_warning "No Android signing configuration found"
fi

# Step 7: Bump version
print_status "Step 7: Bumping version..."
if [ -f "scripts/version-manager.sh" ]; then
    TAG_FLAG=""
    if [ "$CREATE_TAG" = true ]; then
        TAG_FLAG="--tag"
    fi
    
    if bash scripts/version-manager.sh -t "$VERSION_BUMP" --commit $TAG_FLAG; then
        print_success "Version bumped successfully"
        
        # Get new version
        NEW_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
        print_status "New version: $NEW_VERSION"
    else
        print_error "Version bump failed"
        exit 1
    fi
else
    print_warning "Version manager script not found, skipping version bump"
fi

# Step 8: Build the app
if [ "$SKIP_BUILD" = false ]; then
    print_status "Step 8: Building release APK and AAB..."
    
    # Build APK
    print_status "Building APK..."
    if flutter build apk --release --split-per-abi; then
        print_success "APK build completed"
        
        # Show APK sizes
        APK_DIR="build/app/outputs/flutter-apk"
        if [ -d "$APK_DIR" ]; then
            print_status "APK files:"
            for apk in "$APK_DIR"/*.apk; do
                if [ -f "$apk" ]; then
                    size=$(du -h "$apk" | cut -f1)
                    print_status "  $(basename "$apk"): $size"
                fi
            done
        fi
    else
        print_error "APK build failed"
        exit 1
    fi
    
    # Build AAB
    print_status "Building App Bundle..."
    if flutter build appbundle --release; then
        print_success "App Bundle build completed"
        
        # Show AAB size
        AAB_FILE="build/app/outputs/bundle/release/app-release.aab"
        if [ -f "$AAB_FILE" ]; then
            size=$(du -h "$AAB_FILE" | cut -f1)
            print_status "App Bundle: $size"
        fi
    else
        print_error "App Bundle build failed"
        exit 1
    fi
else
    print_warning "Skipping build"
fi

# Step 9: Generate release notes
print_status "Step 9: Generating release notes..."
RELEASE_NOTES_FILE="release_notes.md"
cat > "$RELEASE_NOTES_FILE" << EOF
# Mataresit App Release Notes

## Version: $NEW_VERSION
**Release Date**: $(date +%Y-%m-%d)

### 📱 Downloads
- **APK Files**: Choose the appropriate APK for your device architecture
  - \`app-arm64-v8a-release.apk\` - For most modern Android devices (64-bit ARM)
  - \`app-armeabi-v7a-release.apk\` - For older Android devices (32-bit ARM)
  - \`app-x86_64-release.apk\` - For Android emulators and x86 devices
- **AAB File**: \`app-release.aab\` - For Google Play Store distribution

### 🔧 Technical Details
- **Version**: $NEW_VERSION
- **Flutter Version**: $(flutter --version | head -n 1 | cut -d ' ' -f 2)
- **Minimum Android Version**: API 21 (Android 5.0)
- **Target Android Version**: API 34 (Android 14)

### 📦 Installation Instructions
1. Download the appropriate APK file for your device
2. Enable "Install from unknown sources" in your Android settings
3. Install the APK file
4. Grant necessary permissions when prompted

### 🔒 Security Note
All release builds are signed with our official signing certificate.

### 📋 What's New
- Add your release notes here
- List new features
- List bug fixes
- List improvements

### 🐛 Known Issues
- List any known issues
- Provide workarounds if available

### 🔄 Upgrade Notes
- Any special upgrade instructions
- Breaking changes (if any)
EOF

print_success "Release notes generated: $RELEASE_NOTES_FILE"

# Step 10: Push changes (if requested)
if [ "$PUSH_CHANGES" = true ]; then
    print_status "Step 10: Pushing changes to remote repository..."
    
    if git push && git push --tags; then
        print_success "Changes pushed to remote repository"
    else
        print_error "Failed to push changes"
        exit 1
    fi
else
    print_warning "Skipping push to remote repository"
fi

# Final summary
echo ""
print_success "🎉 Release preparation completed successfully!"
echo ""
echo "📋 Release Summary:"
echo "  Version: $NEW_VERSION"
echo "  Build artifacts:"
if [ "$SKIP_BUILD" = false ]; then
    echo "    - APK files in build/app/outputs/flutter-apk/"
    echo "    - AAB file in build/app/outputs/bundle/release/"
fi
echo "  Release notes: $RELEASE_NOTES_FILE"
echo ""
echo "🚀 Next steps:"
echo "  1. Review the release notes and update with specific changes"
echo "  2. Test the built APK on different devices"
echo "  3. Upload to GitHub releases or app stores"
if [ "$PUSH_CHANGES" = false ]; then
    echo "  4. Push changes: git push && git push --tags"
fi
echo ""
print_success "Ready for release! 🚀"

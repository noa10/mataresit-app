#!/bin/bash

# Flutter Desktop Builds Test Script
# This script helps test desktop builds locally before pushing to CI/CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FLUTTER_VERSION="3.35.3"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "${BLUE}🚀 Flutter Desktop Builds Test Script${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to print status
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

# Check if we're in the right directory
if [[ ! -f "pubspec.yaml" ]]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Check Flutter installation
print_status "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

CURRENT_FLUTTER_VERSION=$(flutter --version | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+')
print_success "Flutter version: $CURRENT_FLUTTER_VERSION"

if [[ "$CURRENT_FLUTTER_VERSION" != "$FLUTTER_VERSION" ]]; then
    print_warning "Expected Flutter version $FLUTTER_VERSION, but found $CURRENT_FLUTTER_VERSION"
    print_warning "Consider updating Flutter to match CI/CD version"
fi

# Check Flutter doctor
print_status "Running Flutter doctor..."
flutter doctor -v

# Check desktop platform support
print_status "Checking desktop platform support..."
flutter config --list | grep -E "(enable-macos-desktop|enable-windows-desktop|enable-linux-desktop)"

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep '^version:' pubspec.yaml | sed 's/.*+//')

print_success "Current app version: $CURRENT_VERSION+$CURRENT_BUILD"

# Install dependencies
print_status "Installing dependencies..."
flutter pub get

# Run tests (optional)
read -p "Run tests before building? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Running tests..."
    flutter test || print_warning "Some tests failed, but continuing with builds"
fi

# Determine which platforms to build
echo ""
echo "Which platforms would you like to test?"
echo "1) All platforms"
echo "2) macOS only"
echo "3) Windows only (if on Windows)"
echo "4) Linux only (if on Linux)"
echo "5) Custom selection"

read -p "Enter your choice (1-5): " -n 1 -r
echo

PLATFORMS=()
case $REPLY in
    1)
        PLATFORMS=("macos" "windows" "linux")
        ;;
    2)
        PLATFORMS=("macos")
        ;;
    3)
        PLATFORMS=("windows")
        ;;
    4)
        PLATFORMS=("linux")
        ;;
    5)
        echo "Select platforms to build:"
        read -p "Build macOS? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && PLATFORMS+=("macos")
        
        read -p "Build Windows? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && PLATFORMS+=("windows")
        
        read -p "Build Linux? (y/N): " -n 1 -r
        echo
        [[ $REPLY =~ ^[Yy]$ ]] && PLATFORMS+=("linux")
        ;;
    *)
        print_error "Invalid choice"
        exit 1
        ;;
esac

if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
    print_error "No platforms selected"
    exit 1
fi

print_status "Selected platforms: ${PLATFORMS[*]}"

# Create build directory
BUILD_DIR="$PROJECT_ROOT/test_builds"
mkdir -p "$BUILD_DIR"

# Build each platform
for platform in "${PLATFORMS[@]}"; do
    echo ""
    print_status "Building for $platform..."
    
    # Check if platform is supported on current OS
    case $platform in
        "windows")
            if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
                print_warning "Windows builds are only supported on Windows. Skipping..."
                continue
            fi
            ;;
        "macos")
            if [[ "$OSTYPE" != "darwin"* ]]; then
                print_warning "macOS builds are only supported on macOS. Skipping..."
                continue
            fi
            ;;
        "linux")
            if [[ "$OSTYPE" != "linux-gnu"* ]]; then
                print_warning "Linux builds are only supported on Linux. Skipping..."
                continue
            fi
            ;;
    esac
    
    # Create debug symbols directory
    mkdir -p debug-symbols
    
    # Build command with optimizations
    BUILD_CMD="flutter build $platform --release --tree-shake-icons --split-debug-info=debug-symbols/"
    
    print_status "Running: $BUILD_CMD"
    
    if $BUILD_CMD; then
        print_success "✅ $platform build completed successfully"
        
        # Verify build output
        case $platform in
            "macos")
                BUILD_PATH="build/macos/Build/Products/Release/mataresit_app.app"
                if [[ -d "$BUILD_PATH" ]]; then
                    print_success "macOS app bundle created: $BUILD_PATH"
                    # Create archive
                    cd "build/macos/Build/Products/Release/"
                    zip -r "$BUILD_DIR/mataresit-macos-$CURRENT_VERSION.zip" mataresit_app.app
                    cd "$PROJECT_ROOT"
                    print_success "Archive created: $BUILD_DIR/mataresit-macos-$CURRENT_VERSION.zip"
                fi
                ;;
            "windows")
                BUILD_PATH="build/windows/x64/runner/Release/mataresit_app.exe"
                if [[ -f "$BUILD_PATH" ]]; then
                    print_success "Windows executable created: $BUILD_PATH"
                    # Create archive
                    cd "build/windows/x64/runner/Release/"
                    7z a "$BUILD_DIR/mataresit-windows-$CURRENT_VERSION.zip" *
                    cd "$PROJECT_ROOT"
                    print_success "Archive created: $BUILD_DIR/mataresit-windows-$CURRENT_VERSION.zip"
                fi
                ;;
            "linux")
                BUILD_PATH="build/linux/x64/release/bundle/mataresit_app"
                if [[ -f "$BUILD_PATH" ]]; then
                    print_success "Linux executable created: $BUILD_PATH"
                    # Create archive
                    cd "build/linux/x64/release/bundle/"
                    tar -czf "$BUILD_DIR/mataresit-linux-$CURRENT_VERSION.tar.gz" *
                    cd "$PROJECT_ROOT"
                    print_success "Archive created: $BUILD_DIR/mataresit-linux-$CURRENT_VERSION.tar.gz"
                fi
                ;;
        esac
    else
        print_error "❌ $platform build failed"
    fi
done

# Summary
echo ""
print_status "Build Summary"
print_status "============="

if [[ -d "$BUILD_DIR" ]]; then
    print_status "Build artifacts created in: $BUILD_DIR"
    ls -la "$BUILD_DIR"
    
    echo ""
    print_status "Archive sizes:"
    du -h "$BUILD_DIR"/* 2>/dev/null || true
fi

echo ""
print_success "🎉 Desktop build testing completed!"
print_status "You can now test the applications locally before pushing to CI/CD"

# Cleanup option
echo ""
read -p "Clean up build directories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up build directories..."
    rm -rf build/
    rm -rf debug-symbols/
    print_success "Cleanup completed"
fi

print_status "Script completed successfully! 🚀"

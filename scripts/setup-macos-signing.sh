#!/bin/bash

# macOS Code Signing Setup Script
# This script helps set up code signing for the macOS Flutter app

set -e

echo "🔐 macOS Code Signing Setup for Mataresit App"
echo "=============================================="
echo ""

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode is not installed or not in PATH"
    echo "Please install Xcode from the App Store and try again."
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "macos/Runner.xcworkspace" ]; then
    echo "❌ Error: This script must be run from the Flutter project root directory"
    echo "Current directory: $(pwd)"
    echo "Expected to find: macos/Runner.xcworkspace"
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo "✅ Project structure verified"
echo ""

# Check for development certificates
echo "🔍 Checking for macOS development certificates..."
CERTS=$(security find-identity -v -p codesigning | grep "Mac Developer\|Apple Development" | wc -l | tr -d ' ')

if [ "$CERTS" -eq 0 ]; then
    echo "⚠️  No macOS development certificates found in keychain"
    echo ""
    echo "To fix this, you need to:"
    echo "1. Log in to https://developer.apple.com"
    echo "2. Go to Certificates, Identifiers & Profiles"
    echo "3. Create a new macOS Development certificate"
    echo "4. Download and install it in Keychain Access"
    echo ""
    echo "Or use Xcode to automatically manage signing (recommended)."
else
    echo "✅ Found $CERTS macOS development certificate(s)"
    echo ""
    echo "Available certificates:"
    security find-identity -v -p codesigning | grep "Mac Developer\|Apple Development"
fi

echo ""
echo "🛠️  Next Steps:"
echo "==============="
echo ""
echo "1. Open the project in Xcode:"
echo "   open macos/Runner.xcworkspace"
echo ""
echo "2. Select the 'Runner' target in the project navigator"
echo ""
echo "3. Go to the 'Signing & Capabilities' tab"
echo ""
echo "4. Enable 'Automatically manage signing'"
echo ""
echo "5. Select your development team from the dropdown"
echo ""
echo "6. Verify these entitlements are configured:"
echo "   ✅ App Sandbox"
echo "   ✅ Network Client"
echo "   ✅ Network Server" 
echo "   ✅ Keychain Sharing (com.google.GIDSignIn)"
echo ""
echo "7. Build the app:"
echo "   flutter build macos --debug"
echo ""
echo "8. Test Google OAuth authentication"
echo ""

# Check if user wants to open Xcode
read -p "Would you like to open the project in Xcode now? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Opening Xcode..."
    open macos/Runner.xcworkspace
    echo ""
    echo "✅ Xcode opened. Please follow the steps above to configure signing."
else
    echo "👍 You can open Xcode manually later with:"
    echo "   open macos/Runner.xcworkspace"
fi

echo ""
echo "📚 For detailed instructions, see: docs/macos-build-setup.md"
echo ""
echo "🎯 Once signing is configured, the Google OAuth authentication fix will be ready to test!"

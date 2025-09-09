#!/bin/bash

# GitHub Secrets Setup Script for Mataresit App
# This script helps you add all required GitHub secrets using GitHub CLI

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

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

print_header "GITHUB SECRETS SETUP FOR MATARESIT APP"

# Check if GitHub CLI is available and authenticated
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI is not installed. Please install it from https://cli.github.com/"
    exit 1
fi

if ! gh auth status > /dev/null 2>&1; then
    echo "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    exit 1
fi

print_success "GitHub CLI is available and authenticated"

print_header "ANDROID SIGNING SECRETS"

# Android Keystore Base64 (from your generated keystore)
KEYSTORE_BASE64="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"

print_status "Adding ANDROID_KEYSTORE_BASE64..."
gh secret set ANDROID_KEYSTORE_BASE64 --body "$KEYSTORE_BASE64"
print_success "ANDROID_KEYSTORE_BASE64 added"

print_status "Add
print_status "Adding ANDRgh secret set ANDROID_KEY_ALIAS --body "mataresit-key"
print_success "ANDROID_KEY_ALIAS added"

print_header "ENVIRONMENT VARIABLES"

print_status "Adding SUPABASE_URL..."
gh secret set SUPABASE_URL --body "https://mpmkbtsufihzdelrlszs.supabase.co"
print_success "SUPABASE_URL added"

print_status "Adding SUPABASE_PROJECT_ID..."
gh secret set SUPABASE_PROJECT_ID --body "mpmkbtsufihzdelrlszs"
print_success "SUPABASE_PROJECT_ID added"

print_header "INTERACTIVE SECRETS"
echo "Now you need to add the passwords and API keys interactively:"
echo ""

# Keystore Password
echo "Enter your keystore password (the one you used when creating the keystore):"
read -s KEYSTORE_PASSWORD
gh secret set ANDROID_KEYSTORE_PASSWORD --body "$KEYSTORE_PASSWORD"
print_success "ANDROID_KEYSTORE_PASSWORD added"

# Key Password (usually same as keystore)
echo ""
echo "Enter your key password (press Enter if same as keystore password):"
read -s KEY_PASSWORD
if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$KEYSTORE_PASSWORD"
fi
gh secret set ANDROID_KEY_PASSWORD --body "$KEY_PASSWORD"
print_success "ANDROID_KEY_PASSWORD added"

# Supabase Anon Key
echo ""
echo "Enter your Supabase Anon Key:"
read -s SUPABASE_ANON_KEY
gh secret set SUPABASE_ANON_KEY --body "$SUPABASE_ANON_KEY"
print_success "SUPABASE_ANON_KEY added"

# Gemini API Key
echo ""
echo "Enter your Gemini API Key:"
read -s GEMINI_API_KEY
gh secret set GEMINI_API_KEY --body "$GEMINI_API_KEY"
print_success "GEMINI_API_KEY added"

print_header "VERIFICATION"
print_status "Listing all repository secrets..."
gh secret list

print_success "🎉 All required GitHub secrets have been added!"
print_status "Your CI/CD pipeline is now ready to run."


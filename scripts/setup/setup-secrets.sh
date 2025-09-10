#!/bin/bash

# Mataresit App - Secrets Setup Helper Script
# This script helps set up and validate GitHub secrets configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_header() {
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --generate-keystore      Generate a new Android keystore"
    echo "  --convert-keystore FILE  Convert keystore to base64"
    echo "  --validate-local         Validate local configuration"
    echo "  --list-secrets           List required GitHub secrets"
    echo "  --check-env              Check environment variables"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --generate-keystore   # Generate new keystore"
    echo "  $0 --validate-local      # Check local setup"
    echo "  $0 --list-secrets        # Show required secrets"
}

# Function to generate keystore
generate_keystore() {
    print_header "GENERATING ANDROID KEYSTORE"
    
    KEYSTORE_NAME="mataresit-release.jks"
    KEY_ALIAS="mataresit"
    
    print_status "This will generate a new Android keystore for app signing"
    print_warning "Make sure to remember the passwords you enter!"
    
    echo ""
    read -p "Enter keystore filename [$KEYSTORE_NAME]: " input_name
    if [ -n "$input_name" ]; then
        KEYSTORE_NAME="$input_name"
    fi
    
    read -p "Enter key alias [$KEY_ALIAS]: " input_alias
    if [ -n "$input_alias" ]; then
        KEY_ALIAS="$input_alias"
    fi
    
    if [ -f "$KEYSTORE_NAME" ]; then
        print_error "Keystore $KEYSTORE_NAME already exists!"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Keystore generation cancelled"
            return
        fi
    fi
    
    print_status "Generating keystore: $KEYSTORE_NAME"
    print_status "Key alias: $KEY_ALIAS"
    
    if keytool -genkey -v -keystore "$KEYSTORE_NAME" \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -alias "$KEY_ALIAS"; then
        
        print_success "Keystore generated successfully: $KEYSTORE_NAME"
        
        # Convert to base64
        print_status "Converting to base64 for GitHub secrets..."
        base64 -i "$KEYSTORE_NAME" | tr -d '\n' > "${KEYSTORE_NAME}.base64"
        print_success "Base64 file created: ${KEYSTORE_NAME}.base64"
        
        # Create key.properties template
        print_status "Creating key.properties file..."
        cat > android/key.properties << EOF
storePassword=ENTER_YOUR_KEYSTORE_PASSWORD
keyPassword=ENTER_YOUR_KEY_PASSWORD
keyAlias=$KEY_ALIAS
storeFile=../$KEYSTORE_NAME
EOF
        
        print_success "Created android/key.properties (update with your passwords)"
        
        echo ""
        print_status "Next steps:"
        echo "1. Edit android/key.properties with your actual passwords"
        echo "2. Add the content of ${KEYSTORE_NAME}.base64 to GitHub secret ANDROID_KEYSTORE_BASE64"
        echo "3. Add your passwords to GitHub secrets"
        echo "4. Keep $KEYSTORE_NAME in a secure location"
        
    else
        print_error "Failed to generate keystore"
    fi
}

# Function to convert keystore to base64
convert_keystore() {
    local keystore_file="$1"
    
    print_header "CONVERTING KEYSTORE TO BASE64"
    
    if [ ! -f "$keystore_file" ]; then
        print_error "Keystore file not found: $keystore_file"
        return 1
    fi
    
    print_status "Converting $keystore_file to base64..."
    
    base64 -i "$keystore_file" | tr -d '\n' > "${keystore_file}.base64"
    
    print_success "Base64 file created: ${keystore_file}.base64"
    print_status "Use the content of this file for ANDROID_KEYSTORE_BASE64 GitHub secret"
    
    # Show first and last few characters for verification
    local base64_content=$(cat "${keystore_file}.base64")
    local content_length=${#base64_content}
    print_status "Base64 content (${content_length} characters): ${base64_content:0:20}...${base64_content: -20}"
}

# Function to validate local configuration
validate_local() {
    print_header "VALIDATING LOCAL CONFIGURATION"
    
    local errors=0
    
    # Check Flutter project
    if [ -f "pubspec.yaml" ]; then
        print_success "Flutter project detected"
    else
        print_error "pubspec.yaml not found - not a Flutter project?"
        ((errors++))
    fi
    
    # Check Android configuration
    if [ -f "android/app/build.gradle.kts" ]; then
        print_success "Android build configuration found"
    else
        print_error "Android build configuration not found"
        ((errors++))
    fi
    
    # Check environment file
    if [ -f ".env" ]; then
        print_success "Environment file (.env) found"
        
        # Check required variables
        required_vars=("SUPABASE_URL" "SUPABASE_ANON_KEY" "GEMINI_API_KEY")
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" .env; then
                print_success "$var configured in .env"
            else
                print_warning "$var not found in .env"
            fi
        done
    else
        print_warning "Environment file (.env) not found"
    fi
    
    # Check Android signing
    if [ -f "android/key.properties" ]; then
        print_success "Android signing configuration found"
        
        # Check if it's still the template
        if grep -q "ENTER_YOUR" android/key.properties; then
            print_warning "key.properties contains template values - update with real passwords"
        fi
    else
        print_warning "Android signing configuration not found"
        print_status "Run with --generate-keystore to create one"
    fi
    
    # Check .gitignore
    if [ -f ".gitignore" ]; then
        print_success ".gitignore found"
        
        # Check important patterns
        patterns=("*.jks" "key.properties" ".env.production")
        for pattern in "${patterns[@]}"; do
            if grep -q "$pattern" .gitignore; then
                print_success ".gitignore includes: $pattern"
            else
                print_warning ".gitignore missing pattern: $pattern"
            fi
        done
    else
        print_error ".gitignore not found"
        ((errors++))
    fi
    
    # Summary
    echo ""
    if [ $errors -eq 0 ]; then
        print_success "Local configuration validation passed!"
    else
        print_error "Local configuration has $errors errors"
    fi
}

# Function to list required secrets
list_secrets() {
    print_header "REQUIRED GITHUB SECRETS"
    
    echo "Android Signing Secrets (Required):"
    echo "  ANDROID_KEYSTORE_BASE64     - Base64 encoded keystore file"
    echo "  ANDROID_KEYSTORE_PASSWORD   - Keystore password"
    echo "  ANDROID_KEY_PASSWORD        - Key password"
    echo "  ANDROID_KEY_ALIAS           - Key alias name"
    echo ""
    
    echo "Environment Variables (Required):"
    echo "  SUPABASE_URL                - Supabase project URL"
    echo "  SUPABASE_ANON_KEY           - Supabase anonymous key"
    echo "  SUPABASE_PROJECT_ID         - Supabase project ID"
    echo "  GEMINI_API_KEY              - Google Gemini AI API key"
    echo ""
    
    echo "Optional Environment Variables:"
    echo "  STRIPE_PUBLIC_KEY           - Stripe public key"
    echo "  STRIPE_PRO_MONTHLY_PRICE_ID - Stripe price ID"
    echo "  STRIPE_PRO_ANNUAL_PRICE_ID  - Stripe price ID"
    echo "  STRIPE_MAX_MONTHLY_PRICE_ID - Stripe price ID"
    echo "  STRIPE_MAX_ANNUAL_PRICE_ID  - Stripe price ID"
    echo "  OPENROUTER_API_KEY          - OpenRouter API key"
    echo "  AWS_ACCESS_KEY_ID           - AWS access key"
    echo "  AWS_SECRET_ACCESS_KEY       - AWS secret key"
    echo ""
    
    print_status "To add secrets to GitHub:"
    echo "1. Go to your repository on GitHub"
    echo "2. Navigate to Settings → Secrets and variables → Actions"
    echo "3. Click 'New repository secret'"
    echo "4. Add each secret with the exact name shown above"
}

# Function to check environment variables
check_env() {
    print_header "CHECKING ENVIRONMENT VARIABLES"
    
    if [ -f ".env" ]; then
        print_status "Checking .env file..."
        
        # Required variables
        required_vars=(
            "SUPABASE_URL"
            "SUPABASE_ANON_KEY"
            "SUPABASE_PROJECT_ID"
            "GEMINI_API_KEY"
        )
        
        # Optional variables
        optional_vars=(
            "STRIPE_PUBLIC_KEY"
            "OPENROUTER_API_KEY"
            "AWS_ACCESS_KEY_ID"
            "AWS_SECRET_ACCESS_KEY"
        )
        
        echo ""
        echo "Required Variables:"
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" .env; then
                value=$(grep "^$var=" .env | cut -d'=' -f2)
                if [ -n "$value" ] && [ "$value" != "your_value_here" ]; then
                    print_success "$var: configured"
                else
                    print_error "$var: empty or placeholder value"
                fi
            else
                print_error "$var: not found"
            fi
        done
        
        echo ""
        echo "Optional Variables:"
        for var in "${optional_vars[@]}"; do
            if grep -q "^$var=" .env; then
                value=$(grep "^$var=" .env | cut -d'=' -f2)
                if [ -n "$value" ] && [ "$value" != "your_value_here" ]; then
                    print_success "$var: configured"
                else
                    print_warning "$var: empty or placeholder value"
                fi
            else
                print_warning "$var: not configured"
            fi
        done
        
    else
        print_error ".env file not found"
        print_status "Create .env file with your configuration"
    fi
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        --generate-keystore)
            generate_keystore
            shift
            ;;
        --convert-keystore)
            if [ -z "$2" ]; then
                print_error "Keystore file path required"
                exit 1
            fi
            convert_keystore "$2"
            shift 2
            ;;
        --validate-local)
            validate_local
            shift
            ;;
        --list-secrets)
            list_secrets
            shift
            ;;
        --check-env)
            check_env
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

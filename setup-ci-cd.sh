#!/bin/bash

# Mataresit App - CI/CD Quick Setup Script
# This script helps you quickly set up the CI/CD pipeline

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

print_header "MATARESIT APP CI/CD SETUP"

print_status "Welcome to the Mataresit App CI/CD setup wizard!"
print_status "This script will help you configure the complete CI/CD pipeline."

# Check prerequisites
print_status "Checking prerequisites..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "pubspec.yaml not found. Please run this script from the Flutter project root."
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first."
    exit 1
fi

# Check if Git is available
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install Git first."
    exit 1
fi

print_success "Prerequisites check passed!"

# Step 1: Make scripts executable
print_header "STEP 1: SETTING UP SCRIPTS"

print_status "Making scripts executable..."
find scripts -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
chmod +x setup-ci-cd.sh 2>/dev/null || true

print_success "Scripts are now executable"

# Step 2: Validate environment
print_header "STEP 2: ENVIRONMENT VALIDATION"

print_status "Running environment validation..."
if [ -f "scripts/validate-environment.sh" ]; then
    ./scripts/validate-environment.sh || print_warning "Environment validation found some issues"
else
    print_warning "Environment validation script not found"
fi

# Step 3: Android signing setup
print_header "STEP 3: ANDROID SIGNING SETUP"

if [ ! -f "android/key.properties" ]; then
    print_status "Android signing not configured yet."
    echo ""
    read -p "Do you want to generate a new keystore? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "scripts/setup-secrets.sh" ]; then
            ./scripts/setup-secrets.sh --generate-keystore
        else
            print_error "setup-secrets.sh script not found"
        fi
    else
        print_status "Skipping keystore generation."
        print_status "You can generate it later with: ./scripts/setup-secrets.sh --generate-keystore"
    fi
else
    print_success "Android signing configuration found"
fi

# Step 4: Environment file setup
print_header "STEP 4: ENVIRONMENT CONFIGURATION"

if [ ! -f ".env" ]; then
    print_status "Creating .env file template..."
    cat > .env << EOF
# Mataresit App Environment Variables
# Update these values with your actual configuration

# Supabase Configuration
SUPABASE_URL=https://mpmkbtsufihzdelrlszs.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_PROJECT_ID=mpmkbtsufihzdelrlszs

# API Keys
GEMINI_API_KEY=your_gemini_api_key_here
OPENROUTER_API_KEY=your_openrouter_api_key_here

# Stripe Configuration (Optional)
STRIPE_PUBLIC_KEY=your_stripe_public_key_here
STRIPE_PRO_MONTHLY_PRICE_ID=your_price_id_here
STRIPE_PRO_ANNUAL_PRICE_ID=your_price_id_here
STRIPE_MAX_MONTHLY_PRICE_ID=your_price_id_here
STRIPE_MAX_ANNUAL_PRICE_ID=your_price_id_here

# AWS Configuration (Optional)
AWS_ACCESS_KEY_ID=your_aws_access_key_here
AWS_SECRET_ACCESS_KEY=your_aws_secret_key_here
EOF
    print_success ".env file created"
    print_warning "Please update .env with your actual values"
else
    print_success ".env file already exists"
fi

# Step 5: Test local setup
print_header "STEP 5: TESTING LOCAL SETUP"

print_status "Testing local build..."
if [ -f "scripts/build-app.sh" ]; then
    echo ""
    read -p "Do you want to test a local build? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/build-app.sh -t debug || print_warning "Local build test failed"
    fi
else
    print_warning "build-app.sh script not found"
fi

print_status "Testing local tests..."
if [ -f "scripts/run-tests.sh" ]; then
    echo ""
    read -p "Do you want to run tests? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/run-tests.sh || print_warning "Some tests failed"
    fi
else
    print_warning "run-tests.sh script not found"
fi

# Step 6: GitHub setup instructions
print_header "STEP 6: GITHUB CONFIGURATION"

print_status "To complete the CI/CD setup, you need to configure GitHub secrets:"
echo ""
echo "Required GitHub Secrets:"
echo "  Android Signing:"
echo "    - ANDROID_KEYSTORE_BASE64"
echo "    - ANDROID_KEYSTORE_PASSWORD"
echo "    - ANDROID_KEY_PASSWORD"
echo "    - ANDROID_KEY_ALIAS"
echo ""
echo "  Environment Variables:"
echo "    - SUPABASE_URL"
echo "    - SUPABASE_ANON_KEY"
echo "    - SUPABASE_PROJECT_ID"
echo "    - GEMINI_API_KEY"
echo "    - (and other API keys as needed)"
echo ""
print_status "To add secrets:"
echo "  1. Go to your GitHub repository"
echo "  2. Navigate to Settings → Secrets and variables → Actions"
echo "  3. Click 'New repository secret'"
echo "  4. Add each secret with the exact name shown above"
echo ""

if [ -f "scripts/setup-secrets.sh" ]; then
    print_status "For detailed instructions, run: ./scripts/setup-secrets.sh --list-secrets"
fi

# Step 7: Final validation
print_header "STEP 7: FINAL VALIDATION"

print_status "Running final validation..."
ISSUES=0

# Check critical files
critical_files=(
    ".github/workflows/ci-cd.yml"
    ".github/workflows/pr-check.yml"
    "scripts/build-app.sh"
    "scripts/run-tests.sh"
    "android/app/build.gradle.kts"
)

for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        ((ISSUES++))
    fi
done

# Check .gitignore
if grep -q "key.properties" .gitignore && grep -q "*.jks" .gitignore; then
    print_success ".gitignore is properly configured"
else
    print_warning ".gitignore may need security-related entries"
fi

# Summary
print_header "SETUP COMPLETE"

if [ $ISSUES -eq 0 ]; then
    print_success "🎉 CI/CD setup completed successfully!"
    echo ""
    echo "📋 Next Steps:"
    echo "  1. Update .env with your actual values"
    echo "  2. Configure GitHub secrets (see instructions above)"
    echo "  3. Test the pipeline by creating a pull request"
    echo "  4. Review the documentation in docs/ folder"
    echo ""
    echo "📚 Documentation:"
    echo "  - docs/CI_CD_README.md - Complete CI/CD documentation"
    echo "  - docs/SECURITY_SETUP.md - Security configuration guide"
    echo "  - docs/TESTING_VALIDATION_GUIDE.md - Testing procedures"
    echo ""
    echo "🚀 Your Mataresit app is now ready for automated CI/CD!"
else
    print_error "Setup completed with $ISSUES issues"
    print_status "Please fix the issues above before using the CI/CD pipeline"
fi

echo ""
print_status "Thank you for using the Mataresit CI/CD setup wizard!"

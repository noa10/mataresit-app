# 🔧 Environment Configuration Guide

## Overview

This guide explains how to properly configure environment variables for the Mataresit Flutter app across different environments (development, CI/CD, production).

## 🚨 **Important Security Note**

The `.env` file has been **removed from pubspec.yaml assets** for security reasons. Environment variables should be handled through:
- Local `.env` files for development (not committed)
- GitHub Secrets for CI/CD
- Platform-specific environment configuration for production

## 📁 **File Structure**

```
mataresit-app/
├── .env                    # Local development (not committed)
├── .env.example           # Template file (committed)
├── .gitignore            # Ensures .env is not committed
└── lib/core/config/      # Environment configuration code
```

## 🛠️ **Development Setup**

### 1. Create Local .env File

Copy the example file and update with your actual values:

```bash
cp .env.example .env
```

### 2. Update .env with Real Values

```env
# Supabase Configuration
SUPABASE_URL=https://mpmkbtsufihzdelrlszs.supabase.co
SUPABASE_ANON_KEY=your_actual_anon_key_here
SUPABASE_PROJECT_ID=mpmkbtsufihzdelrlszs

# Stripe Configuration
STRIPE_PUBLIC_KEY=pk_live_your_actual_stripe_key
STRIPE_PRO_MONTHLY_PRICE_ID=price_actual_id
STRIPE_PRO_ANNUAL_PRICE_ID=price_actual_id
STRIPE_MAX_MONTHLY_PRICE_ID=price_actual_id
STRIPE_MAX_ANNUAL_PRICE_ID=price_actual_id

# API Keys
GEMINI_API_KEY=your_actual_gemini_key
OPENROUTER_API_KEY=your_actual_openrouter_key

# AWS Configuration
AWS_ACCESS_KEY_ID=your_actual_aws_key
AWS_SECRET_ACCESS_KEY=your_actual_aws_secret
```

### 3. Load Environment Variables in Code

Update your Flutter code to load environment variables properly:

```dart
// lib/core/config/environment.dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> initialize() async {
    // Try to load .env file for development
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Fallback to system environment variables for production
      print('No .env file found, using system environment variables');
    }
  }

  static String get supabaseUrl => 
    dotenv.env['SUPABASE_URL'] ?? Platform.environment['SUPABASE_URL'] ?? '';
  
  static String get supabaseAnonKey => 
    dotenv.env['SUPABASE_ANON_KEY'] ?? Platform.environment['SUPABASE_ANON_KEY'] ?? '';
  
  // Add other environment variables as needed
}
```

## 🔄 **CI/CD Configuration**

### GitHub Actions Secrets

Add these secrets to your GitHub repository:

1. Go to **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:

```
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_PROJECT_ID
STRIPE_PUBLIC_KEY
STRIPE_PRO_MONTHLY_PRICE_ID
STRIPE_PRO_ANNUAL_PRICE_ID
STRIPE_MAX_MONTHLY_PRICE_ID
STRIPE_MAX_ANNUAL_PRICE_ID
GEMINI_API_KEY
OPENROUTER_API_KEY
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

### Android Signing Secrets (Optional)

For release builds, add these secrets:

```
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEYSTORE_BASE64  # Base64 encoded keystore file
```

## 🏗️ **Workflow Integration**

The performance monitoring workflow now creates a minimal `.env` file for CI builds:

```yaml
- name: Create minimal .env for build
  run: |
    cat > .env << EOF
    SUPABASE_URL=${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY=${{ secrets.SUPABASE_ANON_KEY }}
    # ... other variables
    EOF
```

## 🔒 **Security Best Practices**

### ✅ **Do:**
- Use GitHub Secrets for sensitive data in CI/CD
- Keep `.env` files out of version control
- Use different keys for development/staging/production
- Regularly rotate API keys and secrets
- Use minimal permissions for API keys

### ❌ **Don't:**
- Commit `.env` files to version control
- Put secrets directly in workflow files
- Use production keys in development
- Share API keys in plain text
- Include `.env` in Flutter assets

## 🐛 **Troubleshooting**

### Common Issues

#### 1. "No file or variants found for asset: .env"
**Solution:** The `.env` file has been removed from assets. Update your code to use `flutter_dotenv` package instead.

#### 2. Environment variables not loading
**Solution:** Ensure you're calling `Environment.initialize()` before using any environment variables.

#### 3. CI/CD builds failing due to missing secrets
**Solution:** Add all required secrets to GitHub repository settings.

#### 4. Android signing errors in CI/CD
**Solution:** The workflow now uses debug builds for size analysis to avoid signing issues.

## 📚 **Dependencies**

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

## 🔄 **Migration Steps**

If you're migrating from the old asset-based approach:

1. ✅ Remove `.env` from `pubspec.yaml` assets (already done)
2. ✅ Update workflows to create `.env` files dynamically (already done)
3. 🔄 Update Flutter code to use `flutter_dotenv`
4. 🔄 Add GitHub Secrets to repository
5. 🔄 Test CI/CD workflows

## 📞 **Support**

If you encounter issues:
1. Check the [Troubleshooting section](#-troubleshooting)
2. Verify all GitHub Secrets are properly set
3. Test locally with a proper `.env` file
4. Check workflow logs for specific error messages

---

**Security Note:** Never commit actual API keys or secrets to version control. Always use environment variables or secure secret management systems.

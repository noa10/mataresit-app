#!/bin/bash

echo "🔍 Testing Mataresit Flutter App Configuration..."
echo ""

# Check if .env file exists
if [ -f ".env" ]; then
    echo "✅ .env file found"
    
    # Check if GEMINI_API_KEY is in .env
    if grep -q "GEMINI_API_KEY=" .env; then
        GEMINI_KEY=$(grep "GEMINI_API_KEY=" .env | cut -d'=' -f2)
        if [ -n "$GEMINI_KEY" ] && [ "$GEMINI_KEY" != "your_gemini_api_key_here" ]; then
            echo "✅ GEMINI_API_KEY found in .env file: ${GEMINI_KEY:0:10}..."
        else
            echo "❌ GEMINI_API_KEY is empty or placeholder in .env file"
        fi
    else
        echo "❌ GEMINI_API_KEY not found in .env file"
    fi
else
    echo "❌ .env file not found"
fi

echo ""
echo "📦 Checking Flutter dependencies..."

# Check if flutter_dotenv is in pubspec.yaml
if grep -q "flutter_dotenv:" pubspec.yaml; then
    echo "✅ flutter_dotenv package found in pubspec.yaml"
else
    echo "❌ flutter_dotenv package NOT found in pubspec.yaml"
fi

# Check if .env is in assets
if grep -A5 "assets:" pubspec.yaml | grep -q ".env"; then
    echo "✅ .env file added to assets in pubspec.yaml"
else
    echo "❌ .env file NOT added to assets in pubspec.yaml"
fi

echo ""
echo "🚀 Ready to test!"
echo "Run: flutter run"
echo "Then go to Debug Screen > Test Gemini Vision Service"
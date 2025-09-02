# Troubleshooting Guide: Receipt Processing Errors

## Based on Error Analysis

Since you mentioned there are still errors with the UI and upload logs, here are the most common issues and their solutions:

## Common Issues and Solutions

### 1. **Gemini API Key Not Configured**

**Symptoms:**
- Error: "Gemini API key is not configured"
- Receipt processing fails immediately
- Debug screen shows API key as "Not set"

**Solution:**
```bash
# Set the environment variable (replace with your actual key)
export GEMINI_API_KEY="AIzaSyC_your_actual_api_key_here"

# Verify it's set
echo $GEMINI_API_KEY

# For permanent setup, add to your shell profile:
echo 'export GEMINI_API_KEY="AIzaSyC_your_actual_api_key_here"' >> ~/.zshrc
source ~/.zshrc
```

### 2. **API Key Invalid or Expired**

**Symptoms:**
- Error: "403 Forbidden" or "Invalid API key"
- Network requests fail
- Gemini service initialization succeeds but processing fails

**Solution:**
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Generate a new API key
3. Ensure the key has access to Gemini models
4. Update your environment variable

### 3. **Model Not Available**

**Symptoms:**
- Error: "Model not found" or "400 Bad Request"
- Processing fails with API errors

**Solution:**
The app now uses `gemini-1.5-flash` (stable model) instead of the newer `gemini-2.0-flash-lite`. This should resolve model availability issues.

### 4. **Network Connectivity Issues**

**Symptoms:**
- Timeout errors
- "Network error" messages
- Processing gets stuck

**Solution:**
- Check internet connection
- Try with different network (mobile data vs WiFi)
- Restart the app

### 5. **Image Processing Issues**

**Symptoms:**
- "Image file too large" error
- "Failed to process receipt" with image-related errors
- Processing succeeds but returns low confidence

**Solution:**
- Use images under 5MB
- Ensure good lighting and clear text
- Try cropping the receipt to remove background
- Use PNG or JPEG format

## Quick Diagnostic Steps

### Step 0: Verify .env Configuration (NEW!)
```bash
# Check if configuration is correct
cd /Users/khairulanwar/dev/mataresit-app
./check_config.sh
```

**Expected output:**
```
✅ .env file found
✅ GEMINI_API_KEY found in .env file: AIzaSyAqp9...
✅ flutter_dotenv package found in pubspec.yaml
✅ .env file added to assets in pubspec.yaml
```

### Step 1: Check API Key Configuration
```bash
# Run this in terminal to check if API key is set
cd /Users/khairulanwar/dev/mataresit-app
flutter run
```

Then in the app:
1. Open the debug screen
2. Tap "Test Gemini Vision Service"
3. Check the status output

### Step 2: Test with Simple Image
1. Use a clear, well-lit receipt image
2. Keep image size under 2MB
3. Ensure receipt text is clearly visible

### Step 3: Check Console Logs
Look for these specific error patterns:

**API Key Issues:**
```
❌ Gemini API key is not set
❌ Gemini Vision Service not initialized
```

**Network Issues:**
```
❌ Error processing receipt image: SocketException
❌ Failed to process receipt: TimeoutException
```

**Parsing Issues:**
```
❌ Error parsing receipt data: FormatException
❌ Failed to parse receipt data: JSON decode failed
```

## Environment Setup Verification

Create a simple test script to verify your setup:

```bash
#!/bin/bash
echo "🔍 Checking Mataresit App Configuration..."
echo ""

# Check Flutter
echo "📱 Flutter version:"
flutter --version | head -1

# Check environment variables
echo ""
echo "🔑 Environment variables:"
if [ -z "$GEMINI_API_KEY" ]; then
    echo "❌ GEMINI_API_KEY: Not set"
else
    echo "✅ GEMINI_API_KEY: ${GEMINI_API_KEY:0:10}..."
fi

# Check dependencies
echo ""
echo "📦 Flutter dependencies:"
cd /Users/khairulanwar/dev/mataresit-app
flutter pub deps | grep google_generative_ai

echo ""
echo "🚀 Ready to test? Run: flutter run"
```

## If You're Still Getting Errors

Please provide the specific error messages you're seeing. Common locations for error logs:

1. **Flutter Console:** Run `flutter run` and check the terminal output
2. **Debug Screen:** In the app, go to debug screen and test services
3. **Device Logs:** Use `flutter logs` to see device-specific errors

### Error Log Format to Share:
```
Error Type: [UI Error / Upload Error / Processing Error]
Error Message: [Exact error text]
Stack Trace: [If available]
When it occurs: [During upload / During processing / After processing]
Image details: [File size, format, content]
```

## Advanced Debugging

### Enable Detailed Logging
The app now includes enhanced logging. Look for these log prefixes:

- `🔧 Initializing...` - Service initialization
- `🔍 Processing...` - Image processing steps  
- `✅ Success:` - Successful operations
- `❌ Error:` - Error conditions
- `⚠️ Warning:` - Warning conditions

### Test Gemini Service Directly

You can test the Gemini service independently:

1. Open debug screen in app
2. Tap "Test Gemini Vision Service"
3. Check output for:
   - Service configuration status
   - API key validation
   - Connection test results

### Common Fix: Restart App After Environment Changes

After setting the `GEMINI_API_KEY` environment variable:
1. Close the Flutter app completely
2. Stop the Flutter development server (`Ctrl+C`)
3. Restart with `flutter run`
4. The app will reinitialize with the new environment variable

## Contact for Further Help

If these steps don't resolve your issue, please share:
1. The exact error message from the UI
2. The console output when the error occurs
3. The image you're trying to process (if you can share it)
4. Your environment details (Flutter version, OS, etc.)

The fixes implemented should resolve most common issues, but specific error details will help identify any remaining problems.
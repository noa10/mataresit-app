# Mataresit App

A Flutter mobile application for receipt management with AI-powered processing using Google Gemini Vision.

## Features

- **AI Receipt Processing**: Automatic receipt data extraction using Google Gemini Vision API
- **Receipt Management**: Capture, store, and organize receipts
- **Expense Tracking**: Track expenses and categorize transactions
- **Team Collaboration**: Share receipts and manage team expenses
- **Offline Support**: Work offline with automatic sync when connected
- **Multi-platform**: Supports Android, iOS, macOS, and Windows

## Getting Started

### Prerequisites

- Flutter SDK (>=3.9.0)
- Dart SDK
- Android Studio / Xcode / VS Code
- Google Gemini API key
- Supabase account and project

### Environment Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mataresit-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables**
   
   Create a `.env` file in the root directory or set environment variables:
   
   ```bash
   # Required: Google Gemini API Key
   export GEMINI_API_KEY="your_gemini_api_key_here"
   
   # Optional: Supabase Configuration (defaults provided)
   export SUPABASE_URL="your_supabase_url"
   export SUPABASE_ANON_KEY="your_supabase_anon_key"
   
   # Optional: Stripe Configuration
   export STRIPE_PUBLIC_KEY="your_stripe_public_key"
   ```

4. **Get Google Gemini API Key**
   
   - Go to [Google AI Studio](https://aistudio.google.com/)
   - Sign in with your Google account
   - Click "Get API key" and create a new API key
   - Copy the API key and set it as `GEMINI_API_KEY`

5. **Run the application**
   ```bash
   # For development
   flutter run
   
   # For Android release
   flutter build apk
   
   # For iOS release (macOS only)
   flutter build ios
   ```

### Testing the AI Receipt Processing

1. **Open the Debug Screen**
   - Navigate to the debug screen in the app
   - Tap "Test Gemini Vision Service"
   - Verify the service is properly configured

2. **Upload a Receipt**
   - Use the receipt capture feature
   - Take a photo or select an image
   - The AI will automatically extract receipt data

## Configuration

### App Constants

The app uses environment variables for configuration. See `lib/core/constants/app_constants.dart` for all available options:

- `GEMINI_API_KEY`: Required for AI receipt processing
- `SUPABASE_URL`: Backend database URL
- `SUPABASE_ANON_KEY`: Supabase anonymous access key
- `STRIPE_PUBLIC_KEY`: Payment processing (optional)

### Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)
- Maximum file size: 5MB

## Development

### Project Structure

```
lib/
├── app/                    # App configuration and routing
├── core/                   # Core services and utilities
│   ├── constants/         # App constants and configuration
│   ├── network/           # Network and API clients
│   └── services/          # Core services (Gemini, Supabase, etc.)
├── features/              # Feature modules
│   ├── auth/             # Authentication
│   ├── receipts/         # Receipt management
│   ├── teams/            # Team collaboration
│   └── analytics/        # Analytics and reporting
├── shared/               # Shared models, widgets, and utilities
└── debug/                # Debug and testing screens
```

### AI Processing Flow

1. **Image Capture**: User takes/selects receipt image
2. **Preprocessing**: Image validation and optimization
3. **AI Processing**: Google Gemini Vision API extracts data
4. **Data Parsing**: JSON response parsed into structured data
5. **Storage**: Receipt data saved to Supabase database
6. **UI Update**: Receipt displayed with extracted information

## Troubleshooting

### Common Issues

1. **"Gemini API key is not configured"**
   - Ensure `GEMINI_API_KEY` environment variable is set
   - Verify the API key is valid and active

2. **"No response from Gemini Vision API"**
   - Check internet connection
   - Verify API key has necessary permissions
   - Ensure image file is valid and under 5MB

3. **"Failed to parse receipt data"**
   - Receipt image may be unclear or damaged
   - Try with a higher quality image
   - Check debug logs for specific parsing errors

### Debug Features

- Use the Debug Screen to test services
- Check console logs for detailed error information
- Monitor network requests in debug mode

## Contributing

Please read the contribution guidelines and follow the code style defined in `analysis_options.yaml`.

## License

This project is licensed under the MIT License.

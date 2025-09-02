---
type: "always_apply"
---

# Mataresit Project Configuration
- Mataresit project uses Supabase URL https://mpmkbtsufihzdelrlszs.supabase.co with specific anon/service role keys, integrates with Stripe for payments, Supabase for storage, and Gemini/OpenRouter APIs for AI features.
- Mataresit project uses Google Gemini AI Vision API for receipt image analysis and data extraction instead of traditional OCR methods, with the existing Gemini API key from configuration.

# Platform Development
- Use the React app implementation in mataresit folder as a reference point to understand how the app works.
- The Flutter app should achieve feature parity with the React web version.
- Never touch the react app in Mataresit folder. Use it only as reference point for flutter development
- When debugging Flutter app features, use the React web app implementation in mataresit folder only as reference without modifying it, and ensure Flutter achieves feature parity with the React version.
- Mataresit project has both React web version (already properly integrated with Supabase categories) and Flutter Android version (still using mockup category data) that need feature parity.
- Mataresit app receipt details screen should follow mobile-first design principles, display line items with clear visual hierarchy, include edit functionality for receipt data and line items, and maintain consistency between React web and Flutter Android versions.
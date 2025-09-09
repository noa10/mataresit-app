# Mataresit App - ProGuard Rules
# Add project specific ProGuard rules here.

# Keep Flutter and Dart classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Supabase classes
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Keep Google AI classes
-keep class com.google.ai.** { *; }
-dontwarn com.google.ai.**

# Keep image processing libraries
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# Keep local auth classes
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Keep notification classes
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Keep JSON serialization
-keepattributes *Annotation*
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep model classes (adjust package names as needed)
-keep class mataresit.co.mataresit_app.models.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# Optimize and obfuscate
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "mataresit.co.mataresit_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring for Java 8+ language features
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    defaultConfig {
        applicationId = "mataresit.co.mataresit_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for large apps
        multiDexEnabled = true

        // Vector drawable support
        vectorDrawables.useSupportLibrary = true
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            debuggable = true
            minifyEnabled = false
            shrinkResources = false
        }

        release {
            // Use release signing config if available, otherwise fall back to debug
            signingConfig = keystoreProperties['storeFile'] ? signingConfigs.release : signingConfigs.debug
            minifyEnabled = true
            shrinkResources = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'

            // Optimize for release
            debuggable = false
            jniDebuggable = false
            renderscriptDebuggable = false
            zipAlignEnabled = true
        }

        profile {
            initWith debug
            applicationIdSuffix = ".profile"
            debuggable = false
            minifyEnabled = true
            shrinkResources = true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }

    // Split APKs by ABI for smaller download sizes
    splits {
        abi {
            enable = true
            reset()
            include "arm64-v8a", "armeabi-v7a", "x86_64"
            universalApk = false
        }
    }

    // Packaging options
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjsc.so'
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring dependency for Java 8+ language features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

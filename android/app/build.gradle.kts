import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    println("Loaded keystore properties from: ${keystorePropertiesFile.absolutePath}")
    println("Key alias: ${keystoreProperties["keyAlias"]}")
    println("Store file: ${keystoreProperties["storeFile"]}")
} else {
    println("Keystore properties file not found at: ${keystorePropertiesFile.absolutePath}")
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
        create("release") {
            val keyAliasValue = keystoreProperties["keyAlias"] as String?
            val keyPasswordValue = keystoreProperties["keyPassword"] as String?
            val storeFileValue = keystoreProperties["storeFile"] as String?
            val storePasswordValue = keystoreProperties["storePassword"] as String?

            if (keyAliasValue.isNullOrEmpty()) {
                println("ERROR: keyAlias is null or empty - check ANDROID_KEY_ALIAS secret")
            }
            if (storeFileValue.isNullOrEmpty()) {
                println("ERROR: storeFile is null or empty - check key.properties file")
            }
            if (keyPasswordValue.isNullOrEmpty()) {
                println("ERROR: keyPassword is null or empty - check ANDROID_KEY_PASSWORD secret")
            }
            if (storePasswordValue.isNullOrEmpty()) {
                println("ERROR: storePassword is null or empty - check ANDROID_KEYSTORE_PASSWORD secret")
            }

            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
            storeFile = if (!storeFileValue.isNullOrEmpty()) {
                println("Current working directory: ${System.getProperty("user.dir")}")
                println("Project directory: ${project.projectDir}")
                println("Root project directory: ${rootProject.projectDir}")

                val keystoreFile = file(storeFileValue)
                println("Looking for keystore at: ${keystoreFile.absolutePath}")

                if (!keystoreFile.exists()) {
                    println("ERROR: Keystore file does not exist at: ${keystoreFile.absolutePath}")

                    // Try multiple alternative paths
                    val alternatives = listOf(
                        file("keystore.jks"),
                        file("../keystore.jks"),
                        rootProject.file("android/app/keystore.jks"),
                        project.file("keystore.jks")
                    )

                    var foundFile: File? = null
                    for (altFile in alternatives) {
                        println("Trying alternative path: ${altFile.absolutePath}")
                        if (altFile.exists()) {
                            println("Found keystore at alternative path: ${altFile.absolutePath}")
                            foundFile = altFile
                            break
                        }
                    }

                    foundFile ?: keystoreFile
                } else {
                    println("Found keystore at: ${keystoreFile.absolutePath}")
                    keystoreFile
                }
            } else null
            storePassword = storePasswordValue
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
        getByName("debug") {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }

        getByName("release") {
            // Use release signing config if all required properties are available
            val storeFileValue = keystoreProperties["storeFile"] as String?
            val keyAliasValue = keystoreProperties["keyAlias"] as String?
            val storePasswordValue = keystoreProperties["storePassword"] as String?
            val keyPasswordValue = keystoreProperties["keyPassword"] as String?

            val hasValidSigningConfig = !storeFileValue.isNullOrEmpty() &&
                                      !keyAliasValue.isNullOrEmpty() &&
                                      !storePasswordValue.isNullOrEmpty() &&
                                      !keyPasswordValue.isNullOrEmpty()

            signingConfig = if (hasValidSigningConfig) {
                println("Using release signing configuration")
                signingConfigs.getByName("release")
            } else {
                println("Warning: Missing signing properties, falling back to debug signing")
                signingConfigs.getByName("debug")
            }

            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")

            // Optimize for release
            isDebuggable = false
            isJniDebuggable = false
        }

        getByName("profile") {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }



    // Packaging options
    packaging {
        jniLibs {
            pickFirsts.add("**/libc++_shared.so")
            pickFirsts.add("**/libjsc.so")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring dependency for Java 8+ language features
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

import java.util.Base64
import java.util.Properties
import java.io.FileInputStream

// remove this when flutter fix following issue:
// https://github.com/flutter/flutter/issues/139289
val dartDefines: Map<String, String> = if (gradle.startParameter.projectProperties.containsKey("dart-defines")) {
    val encoded = gradle.startParameter.projectProperties["dart-defines"]!!
    encoded.split(",").associate { entry ->
        val decoded = String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
        val (key, value) = decoded.split("=")
        key to value
    }
} else {
    emptyMap()
}

fun loadKeystoreProperties(keystoreFilePath: String): Properties {
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file(keystoreFilePath)
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }
    return keystoreProperties
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // flutter.minSdkVersion

        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // --dart-define-from-file=configs/example.json
        resValue("string", "app_name", dartDefines["APP_NAME"] ?: "StoryPad C.")
    }

    signingConfigs {
        create("release") {
            val envKeystorePath = System.getenv("RELEASE_KEYSTORE_PATH")
            val envKeystorePassword = System.getenv("RELEASE_KEYSTORE_PASSWORD")
            val envKeyAlias = System.getenv("RELEASE_KEY_ALIAS")
            val envKeyPassword = System.getenv("RELEASE_KEY_PASSWORD")

            if (envKeystorePath != null) {
                storeFile = file(envKeystorePath)
                storePassword = envKeystorePassword
                keyAlias = envKeyAlias
                keyPassword = envKeyPassword
            }
        }

        getByName("debug") {
            val envKeystorePath = System.getenv("DEBUG_KEYSTORE_PATH")
            val envKeystorePassword = System.getenv("DEBUG_KEYSTORE_PASSWORD")
            val envKeyAlias = System.getenv("DEBUG_KEY_ALIAS")
            val envKeyPassword = System.getenv("DEBUG_KEY_PASSWORD")

            if (envKeystorePath != null) {
                storeFile = file(envKeystorePath)
                storePassword = envKeystorePassword
                keyAlias = envKeyAlias
                keyPassword = envKeyPassword
            }
        }
    }

    flavorDimensions.add("app")
    productFlavors {
        create("spooky") {
            dimension = "app"
            applicationId = "com.juniorise.spooky"
            namespace = "com.juniorise.spooky"
        }

        create("storypad") {
            dimension = "app"
            applicationId = "com.tc.writestory"
            namespace = "com.tc.writestory"
        }

        create("community") {
            dimension = "app"
            applicationId = "com.juniorise.spooky.community"
            namespace = "com.juniorise.spooky.community"
        }
    }

    buildTypes {
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }

        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

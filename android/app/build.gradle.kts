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
        resValue("string", "app_name", dartDefines["APP_NAME"] ?: "Spooky")
    }

    signingConfigs {
        create("spookyRelease") {
            val keystoreProperties = loadKeystoreProperties("./keys/spooky/spooky_key.properties")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }

        create("storypadRelease") {
            val keystoreProperties = loadKeystoreProperties("./keys/storypad/storypad_key.properties")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }

        create("communityRelease") {
            val keystoreProperties = loadKeystoreProperties("./keys/community/community_key.properties")
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }

        create("spookyDebug") {
            storeFile = rootProject.file("./keys/spooky/spooky_debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }

        create("storypadDebug") {
            storeFile = rootProject.file("./keys/storypad/storypad_debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }

        create("communityDebug") {
            storeFile = rootProject.file("./keys/community/community_debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    flavorDimensions.add("app")
    productFlavors {
        create("spooky") {
            dimension = "app"
            applicationId = "com.juniorise.spooky"
            namespace = "com.juniorise.spooky"
            signingConfig = signingConfigs.getByName("spookyRelease")
        }

        create("storypad") {
            dimension = "app"
            applicationId = "com.tc.writestory"
            namespace = "com.tc.writestory"
            signingConfig = signingConfigs.getByName("storypadRelease")
        }

        create("community") {
            dimension = "app"
            applicationId = "com.juniorise.spooky.community"
            namespace = "com.juniorise.spooky"
            signingConfig = signingConfigs.getByName("communityRelease")
        }
    }

    buildTypes {
        getByName("debug") {
            // signingConfig = signingConfigs.getByName("spookyDebug")
            // signingConfig = signingConfigs.getByName("storypadDebug")
            signingConfig = signingConfigs.getByName("communityDebug")
        }
    }
}

flutter {
    source = "../.."
}

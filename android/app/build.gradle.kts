import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key, kept out of git (see android/key.properties.example).
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) load(FileInputStream(file))
}
val hasReleaseKey = keystoreProperties.containsKey("storeFile")

android {
    namespace = "com.donfreddy.troona"
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
        applicationId = "com.donfreddy.troona"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        // Debug and profile builds install next to the release app ("Troona
        // Dev", DEV banner on the icon) with their own data, so the release
        // app on the phone is never replaced by a development build.
        // Profile is created by the Flutter plugin as a copy of debug before
        // this block runs, so it does not inherit these and is set too.
        debug {
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Troona Dev")
        }
        getByName("profile") {
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Troona Dev")
        }
        release {
            resValue("string", "app_name", "Troona")
            // Without key.properties (CI, a fresh clone) the release build
            // falls back to the debug key so `flutter run --release` works.
            // Never upload such a build: Play rejects debug-signed bundles.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties missing: release signed with the DEBUG key")
                signingConfigs.getByName("debug")
            }
        }
    }
}

// Profile builds get the debug icon (DEV banner) too.
android.sourceSets.getByName("profile").res.srcDir("src/debug/res")

flutter {
    source = "../.."
}

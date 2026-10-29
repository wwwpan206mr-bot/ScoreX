import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val scorexSigningProperties = Properties().apply {
    val propertiesFile = rootProject.file("key.properties")
    if (propertiesFile.exists()) propertiesFile.inputStream().use { load(it) }
}

android {
    namespace = "com.scorex.app.scorex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.scorex.app.scorex"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (scorexSigningProperties.containsKey("storeFile")) {
        signingConfigs.create("githubRelease") {
            storeFile = rootProject.file(scorexSigningProperties.getProperty("storeFile"))
            storePassword = scorexSigningProperties.getProperty("storePassword")
            keyAlias = scorexSigningProperties.getProperty("keyAlias")
            keyPassword = scorexSigningProperties.getProperty("keyPassword")
        }
    }

    buildFeatures { buildConfig = true }
    flavorDimensions += "distribution"
    productFlavors {
        create("github") {
            dimension = "distribution"
            if (scorexSigningProperties.containsKey("storeFile")) {
                signingConfig = signingConfigs.getByName("githubRelease")
            }
        }
        create("play") { dimension = "distribution" }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            // Development fallback only. GitHub release flavor overrides this when key.properties exists.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    add("githubImplementation", "androidx.core:core-ktx:1.17.0")
    add("playImplementation", "com.google.android.play:app-update-ktx:2.1.0")
    add("testGithubImplementation", "junit:junit:4.13.2")
}

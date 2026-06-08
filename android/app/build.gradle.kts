import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.techsate.senteclick.seller"
    compileSdk = 36
    buildToolsVersion = "34.0.0"   // ← add this line
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    defaultConfig {
        applicationId = "com.techsate.senteclick.seller"
        multiDexEnabled = true
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // 1️⃣ Codemagic environment variables (set when keystore is uploaded)
            val cmStoreFile = System.getenv("CM_KEYSTORE_PATH")
            val cmStorePassword = System.getenv("CM_KEYSTORE_PASSWORD")
            val cmKeyAlias = System.getenv("CM_KEY_ALIAS")
            val cmKeyPassword = System.getenv("CM_KEY_PASSWORD")

            if (!cmStoreFile.isNullOrEmpty() && cmStoreFile.isNotBlank()) {
                keyAlias = cmKeyAlias
                keyPassword = cmKeyPassword
                storeFile = file(cmStoreFile)
                storePassword = cmStorePassword
                println("✅ Using Codemagic keystore for vendor app")
            } else if (keystorePropertiesFile.exists()) {
                // 2️⃣ Local key.properties (for development)
                keyAlias = keystoreProperties["keyAlias"] as? String
                keyPassword = keystoreProperties["keyPassword"] as? String
                storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
                storePassword = keystoreProperties["storePassword"] as? String
                println("✅ Using local key.properties for vendor app")
            } else {
                // 3️⃣ Debug fallback (never release this)
                keyAlias = "androiddebugkey"
                keyPassword = "android"
                storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
                storePassword = "android"
                println("⚠️ WARNING: Using DEBUG keystore – DO NOT UPLOAD TO PLAY STORE!")
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            // Optionally enable minification
            // isMinifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
}
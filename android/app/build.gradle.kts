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
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.techsate.senteclick.seller"
        multiDexEnabled = true
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
    create("release") {
        // First, try Codemagic's injected environment variables
        val cmStoreFile = System.getenv("CM_KEYSTORE_PATH")
        val cmStorePassword = System.getenv("CM_KEYSTORE_PASSWORD")
        val cmKeyAlias = System.getenv("CM_KEY_ALIAS")
        val cmKeyPassword = System.getenv("CM_KEY_PASSWORD")

        if (!cmStoreFile.isNullOrEmpty() && cmStoreFile.isNotBlank()) {
            keyAlias = cmKeyAlias
            keyPassword = cmKeyPassword
            storeFile = file(cmStoreFile)
            storePassword = cmStorePassword
            println("✅ Using Codemagic keystore: $cmStoreFile")
        } else if (keystorePropertiesFile.exists()) {
            // Fallback to local key.properties
            keyAlias = keystoreProperties["keyAlias"] as? String
            keyPassword = keystoreProperties["keyPassword"] as? String
            storeFile = keystoreProperties["storeFile"]?.let { file(it.toString()) }
            storePassword = keystoreProperties["storePassword"] as? String
            println("✅ Using key.properties keystore")
        } else {
            // Debug fallback (only for local development)
            keyAlias = "androiddebugkey"
            keyPassword = "android"
            storeFile = file(System.getProperty("user.home") + "/.android/debug.keystore")
            storePassword = "android"
            println("⚠️ WARNING: Using DEBUG keystore – DO NOT upload this AAB to Play Store!")
        }
    }
}
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release") // or "release" if you have real keystore
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.firebase:firebase-messaging:23.4.1")
}

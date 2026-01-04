import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.notificaciones"
    compileSdk = 36 // ✅ CAMBIAR de 35 a 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17 // ✅ CAMBIAR de 11 a 17
        targetCompatibility = JavaVersion.VERSION_17 // ✅ CAMBIAR de 11 a 17
    }

    kotlinOptions {
        jvmTarget = "17" // ✅ CAMBIAR de 11 a 17
    }

    defaultConfig {
        multiDexEnabled = true
        applicationId = "com.example.notificaciones"
        minSdk = flutter.minSdkVersion
        targetSdk = 35 // O 36 si quieres usar las últimas APIs
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            isMinifyEnabled  = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

dependencies {
    implementation("androidx.window:window:1.0.0")
    implementation("androidx.window:window-java:1.0.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4") // ✅ Actualizar versión
}

flutter {
    source = "../.."
}
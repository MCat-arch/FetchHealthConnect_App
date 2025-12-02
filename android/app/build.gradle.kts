import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 1. Load Keystore Properties (Cara Kotlin DSL)
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.aura_bluetooth"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    defaultConfig {
        applicationId = "com.example.aura_bluetooth"
        // Anda bisa ubah ini ke angka (misal 23) jika flutter.minSdkVersion bermasalah
        minSdk = flutter.minSdkVersion 
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 2. Konfigurasi Signing (Harus didefinisikan SEBELUM buildTypes)
    signingConfigs {
        create("release") {
            // Perhatikan casting 'as String' karena Properties mengembalikan Object
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = if (keystoreProperties["storeFile"] != null) {
                file(keystoreProperties["storeFile"] as String)
            } else {
                null
            }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // 3. Tipe Build
    buildTypes {
        getByName("release") {
            // Mengaktifkan signing config yang dibuat di atas
            signingConfig = signingConfigs.getByName("release")
            
            // Opsional: Mengecilkan ukuran APK (Proguard/R8)
            // Jika nanti error saat run release, ubah jadi false
            isMinifyEnabled = true 
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
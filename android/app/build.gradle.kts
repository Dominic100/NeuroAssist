plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.12.0"))
    implementation("com.google.firebase:firebase-analytics")
    
    // Add these dependencies for the notifications plugin
    implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:1.2.2")

    // Fix the Play Core dependencies conflict
    // implementation("com.google.android.play:core:1.10.3") {
    //     exclude(group = "com.google.android.play", module = "core-common")
    // }
    
    // Add ML Kit dependencies
    implementation("com.google.mlkit:text-recognition:16.0.0")
    implementation("com.google.android.gms:play-services-mlkit-text-recognition:19.0.0")

    // Add additional language text recognizers explicitly
    // implementation("com.google.mlkit:text-recognition-chinese:16.0.0")
    // implementation("com.google.mlkit:text-recognition-devanagari:16.0.0")
    // implementation("com.google.mlkit:text-recognition-japanese:16.0.0")
    // implementation("com.google.mlkit:text-recognition-korean:16.0.0")
}

android {
    namespace = "com.example.neuroassist"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.neuroassist"
        minSdk = 23
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            
            // Disable R8 for troubleshooting
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }

    // Add this configuration to resolve the duplicate class issue
    // configurations.all {
    //     resolutionStrategy {
    //         // Force a specific version of the core-common library
    //         force("com.google.android.play:core-common:2.0.3")
    //     }
    // }
}

flutter {
    source = "../.."
}
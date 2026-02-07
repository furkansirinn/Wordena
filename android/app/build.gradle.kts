plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.furkan.wordena"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.furkan.wordena"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        //  Play Console’un istediği SÜRÜM KODU
        // Bu sayı HER YÜKLEMEDE artmalı
        versionCode = 9

        //  Kullanıcıya görünen sürüm adı
        versionName = "1.0.1"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = "upload"
            keyPassword = "123456"
            storeFile = file("my-release-key.keystore")
            storePassword = "123456"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

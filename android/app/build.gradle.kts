import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Şifreleri okumak için kod bloğu
val keyPropertiesFile = rootProject.file("key.properties")
val keyProperties = Properties()
if (keyPropertiesFile.exists()) {
    keyProperties.load(FileInputStream(keyPropertiesFile))
}

// local.properties dosyasını okumak için yardımcı fonksiyon
fun localProperties(key: String, file: String = "local.properties"): String {
    val properties = Properties()
    val localPropertiesFile = rootProject.file(file)
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
        return properties.getProperty(key) ?: ""
    }
    return ""
}

val flutterVersionCode = localProperties("flutter.versionCode")
val flutterVersionName = localProperties("flutter.versionName")

android {
    namespace = "com.example.yusuf_yemek_uygulasi"
    // DÜZENLEME: compileSdk 36 olarak güncellendi
    compileSdk = 36
    // DÜZENLEME: ndkVersion "27.0.12077973" olarak güncellendi
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    defaultConfig {
        applicationId = "com.example.yusuf_yemek_uygulasi"
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = if (flutterVersionCode.isNotEmpty()) flutterVersionCode.toInt() else 1
        versionName = if (flutterVersionName.isNotEmpty()) flutterVersionName else "1.0.0"
    }

    signingConfigs {
        create("release") {
            keyAlias = keyProperties["keyAlias"] as String?
            keyPassword = keyProperties["keyPassword"] as String?
            storeFile = keyProperties["storeFile"]?.let { file(it) }
            storePassword = keyProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}

dependencies { }

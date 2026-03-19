import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

fun keystoreValue(key: String): String? {
    val direct = keystoreProperties.getProperty(key)
    if (!direct.isNullOrBlank()) return direct

    val bomKey = "\uFEFF$key"
    val withBom = keystoreProperties.getProperty(bomKey)
    if (!withBom.isNullOrBlank()) return withBom

    return keystoreProperties
        .entries
        .firstOrNull { (k, _) -> k.toString().trimStart('\uFEFF') == key }
        ?.value
        ?.toString()
}

android {
    namespace = "com.example.classduck_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.classduck_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.create("release") {
                    storeFile = file(keystoreValue("storeFile") ?: error("Missing storeFile in key.properties"))
                    storePassword = keystoreValue("storePassword") ?: error("Missing storePassword in key.properties")
                    keyAlias = keystoreValue("keyAlias") ?: error("Missing keyAlias in key.properties")
                    keyPassword = keystoreValue("keyPassword") ?: error("Missing keyPassword in key.properties")
                }
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

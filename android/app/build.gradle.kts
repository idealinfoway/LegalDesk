import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}


android {
    namespace = "com.example.legalsteward"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required for flutter_local_notifications (Java time API usage)
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "my.legal.desk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val storeFilePath = keystoreProperties["storeFile"]?.toString()
    ?: throw GradleException("Missing 'storeFile' in key.properties")
val storePassword = keystoreProperties["storePassword"]?.toString()
    ?: throw GradleException("Missing 'storePassword' in key.properties")
val keyAlias = keystoreProperties["keyAlias"]?.toString()
    ?: throw GradleException("Missing 'keyAlias' in key.properties")
val keyPassword = keystoreProperties["keyPassword"]?.toString()
    ?: throw GradleException("Missing 'keyPassword' in key.properties")

signingConfigs {
    create("release") {
        storeFile = file(storeFilePath)
        this.storePassword = storePassword
        this.keyAlias = keyAlias
        this.keyPassword = keyPassword
    }
}



buildTypes {
    getByName("release") {
        isMinifyEnabled = true
        isShrinkResources = true
        signingConfig = signingConfigs.getByName("release")
        
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}

}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:2.2.0")
    implementation(platform("com.google.firebase:firebase-bom:34.0.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.android.material:material:1.9.0")  
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}  

flutter {
    source = "../.."
}

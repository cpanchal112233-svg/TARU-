plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.io.FileInputStream
import java.util.Properties

// Release upload signing — secrets live only in gitignored key.properties / keystore files.
// Never fall back to the debug keystore for release (hard invariant).
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseSigningMaterial = keystorePropertiesFile.exists()
if (hasReleaseSigningMaterial) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireReleaseSigningProperty(name: String): String {
    val value = keystoreProperties.getProperty(name)?.trim().orEmpty()
    if (value.isEmpty()) {
        throw GradleException(
            "TARU release signing: '$name' is missing in android/key.properties.",
        )
    }
    return value
}

android {
    namespace = "com.taru.health"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications so scheduled reminders work
        // on older Android versions.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.taru.health"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigningMaterial) {
                keyAlias = requireReleaseSigningProperty("keyAlias")
                keyPassword = requireReleaseSigningProperty("keyPassword")
                storePassword = requireReleaseSigningProperty("storePassword")
                val storePath = requireReleaseSigningProperty("storeFile")
                storeFile = rootProject.file(storePath).also { file ->
                    if (!file.isFile) {
                        throw GradleException(
                            "TARU release signing: storeFile does not exist: ${file.absolutePath}",
                        )
                    }
                }
            }
        }
    }

    buildTypes {
        release {
            // Hard invariant: never silently use debug signing for release.
            if (hasReleaseSigningMaterial) {
                signingConfig = signingConfigs.getByName("release")
            }
            // Minify/shrink remain off until OCR/ML Kit + Crashlytics mapping
            // are validated under R8 for a production track.
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

gradle.taskGraph.whenReady {
    val releaseArtifactTask = allTasks.any { task ->
        val name = task.name
        name == "assembleRelease" ||
            name == "bundleRelease" ||
            name.endsWith("assembleRelease") ||
            name.endsWith("bundleRelease")
    }
    if (releaseArtifactTask && !hasReleaseSigningMaterial) {
        throw GradleException(
            "TARU release signing requires mobile/android/key.properties " +
                "with storeFile, storePassword, keyAlias, and keyPassword, " +
                "plus a keystore file outside Git. " +
                "Debug builds are unaffected. " +
                "Release must not fall back to the debug keystore.",
        )
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
}

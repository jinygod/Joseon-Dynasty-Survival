import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties().apply {
    if (signingPropertiesFile.isFile) {
        signingPropertiesFile.inputStream().use { load(it) }
    }
}

fun signingValue(propertyName: String, environmentName: String): String? =
    signingProperties.getProperty(propertyName)?.trim()?.takeIf { it.isNotEmpty() }
        ?: providers.environmentVariable(environmentName).orNull?.trim()?.takeIf { it.isNotEmpty() }

val releaseSigningValues = mapOf(
    "storeFile" to signingValue("storeFile", "ANDROID_KEYSTORE_PATH"),
    "storePassword" to signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD"),
    "keyAlias" to signingValue("keyAlias", "ANDROID_KEY_ALIAS"),
    "keyPassword" to signingValue("keyPassword", "ANDROID_KEY_PASSWORD"),
)
val releaseSigningEnvironmentNames = mapOf(
    "storeFile" to "ANDROID_KEYSTORE_PATH",
    "storePassword" to "ANDROID_KEYSTORE_PASSWORD",
    "keyAlias" to "ANDROID_KEY_ALIAS",
    "keyPassword" to "ANDROID_KEY_PASSWORD",
)
val missingReleaseSigningValues = releaseSigningValues
    .filterValues { it.isNullOrBlank() }
    .keys
    .sorted()
val releaseStoreFile = releaseSigningValues["storeFile"]?.let(rootProject::file)
val releaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (releaseTaskRequested && missingReleaseSigningValues.isNotEmpty()) {
    val missingDescription = missingReleaseSigningValues.joinToString { key ->
        "$key (${releaseSigningEnvironmentNames.getValue(key)})"
    }
    throw GradleException(
        "Release signing configuration is incomplete. Missing: $missingDescription. " +
            "Configure android/key.properties or the listed environment variables.",
    )
}
if (releaseTaskRequested && releaseStoreFile?.isFile != true) {
    throw GradleException(
        "Release signing keystore does not exist at the configured storeFile. " +
            "Check android/key.properties or ANDROID_KEYSTORE_PATH.",
    )
}

android {
    namespace = "com.pixel.survivor.pixel_survivor"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pixel.survivor.pixel_survivor"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    val releaseSigningConfig = if (
        missingReleaseSigningValues.isEmpty() && releaseStoreFile?.isFile == true
    ) {
        signingConfigs.create("release") {
            storeFile = releaseStoreFile
            storePassword = releaseSigningValues.getValue("storePassword")
            keyAlias = releaseSigningValues.getValue("keyAlias")
            keyPassword = releaseSigningValues.getValue("keyPassword")
        }
    } else {
        null
    }

    buildTypes {
        release {
            signingConfig = releaseSigningConfig
        }
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

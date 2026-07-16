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

val releaseSigningEnvironmentNames = mapOf(
    "storeFile" to "ANDROID_KEYSTORE_PATH",
    "storePassword" to "ANDROID_KEYSTORE_PASSWORD",
    "keyAlias" to "ANDROID_KEY_ALIAS",
    "keyPassword" to "ANDROID_KEY_PASSWORD",
    "uploadCertSha256" to "ANDROID_UPLOAD_CERT_SHA256",
)
val fileSigningValues = releaseSigningEnvironmentNames.keys.associateWith { key ->
    signingProperties.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() }
}
val environmentSigningValues = releaseSigningEnvironmentNames.mapValues { (_, environmentName) ->
    providers.environmentVariable(environmentName).orNull?.trim()?.takeIf { it.isNotEmpty() }
}
val environmentSigningConfigured = environmentSigningValues.values.any { !it.isNullOrBlank() }
val releaseSigningSourcesMixed = signingPropertiesFile.isFile && environmentSigningConfigured
val releaseSigningValues = if (signingPropertiesFile.isFile) {
    fileSigningValues
} else {
    environmentSigningValues
}
val missingReleaseSigningValues = releaseSigningValues
    .filterValues { it.isNullOrBlank() }
    .keys
    .sorted()
val releaseStoreFile = releaseSigningValues["storeFile"]?.let(rootProject::file)
val uploadCertSha256 = releaseSigningValues["uploadCertSha256"]
    ?.replace(":", "")
    ?.uppercase()
val releasePackagingTaskName = Regex(
    "^(assemble|bundle|package).*release.*$",
    RegexOption.IGNORE_CASE,
)

gradle.taskGraph.whenReady {
    val includesReleasePackaging = allTasks.any { task ->
        task.project == project && releasePackagingTaskName.matches(task.name)
    }
    if (includesReleasePackaging) {
        if (releaseSigningSourcesMixed) {
            throw GradleException(
                "Release signing configuration must not mix android/key.properties and " +
                    "ANDROID_* environment variables. Use one complete source.",
            )
        }
        if (missingReleaseSigningValues.isNotEmpty()) {
            val missingDescription = missingReleaseSigningValues.joinToString { key ->
                "$key (${releaseSigningEnvironmentNames.getValue(key)})"
            }
            throw GradleException(
                "Release signing configuration is incomplete. Missing: $missingDescription. " +
                    "Configure one complete source: android/key.properties or environment variables.",
            )
        }
        if (releaseStoreFile?.isFile != true) {
            throw GradleException(
                "Release signing keystore does not exist at the configured storeFile. " +
                    "Check android/key.properties or ANDROID_KEYSTORE_PATH.",
            )
        }
        if (uploadCertSha256?.matches(Regex("^[0-9A-F]{64}$")) != true) {
            throw GradleException(
                "Release upload certificate SHA-256 must contain exactly 64 hexadecimal digits.",
            )
        }
    }
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
        !releaseSigningSourcesMixed &&
            missingReleaseSigningValues.isEmpty() &&
            releaseStoreFile?.isFile == true &&
            uploadCertSha256?.matches(Regex("^[0-9A-F]{64}$")) == true
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

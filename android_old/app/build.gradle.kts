@Suppress("UnstableApiUsage")
plugins {
    id("com.android.application")
    kotlin("android")
}

android {
    namespace = "com.divergent.alliance"

    compileSdk = 34

    defaultConfig {
        applicationId = "com.divergent.alliance"
        minSdk = 21
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Needed for flutter embedding to find the generated files
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // For now use debug signing to unblock builds, change for Play releases
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // keep defaults
        }
    }

    // Java/Kotlin options
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // This keeps resources from shrinking Flutter assets
    packaging {
        resources {
            excludes += setOf(
                "META-INF/*",
                "META-INF/DEPENDENCIES",
                "META-INF/NOTICE",
                "META-INF/LICENSE"
            )
        }
    }
}

// --- Flutter glue (Kotlin DSL equivalent of the flutter {} block in Groovy) ---
// If your project uses the Flutter Gradle plugin, apply it here:
apply(from = "../../flutter.gradle.kts", to = project) // If you

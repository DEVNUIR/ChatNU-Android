plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

fun q(value: String) = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""

val releaseKeystorePath = System.getenv("CHATNU_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("CHATNU_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("CHATNU_KEY_ALIAS")
val releaseKeyPassword = System.getenv("CHATNU_KEY_PASSWORD")

android {
    namespace = "com.example"
    compileSdk = 36

    defaultConfig {
        applicationId = "ir.devnu.chatnu"
        minSdk = 24
        targetSdk = 36
        versionCode = 3
        versionName = "1.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        buildConfigField("String", "FIREBASE_APP_ID", q(System.getenv("FIREBASE_APP_ID") ?: ""))
        buildConfigField("String", "FIREBASE_API_KEY", q(System.getenv("FIREBASE_API_KEY") ?: ""))
        buildConfigField("String", "FIREBASE_PROJECT_ID", q(System.getenv("FIREBASE_PROJECT_ID") ?: ""))
        buildConfigField("String", "FIREBASE_SENDER_ID", q(System.getenv("FIREBASE_SENDER_ID") ?: ""))
    }

    signingConfigs {
        if (
            !releaseKeystorePath.isNullOrBlank() &&
            !releaseKeystorePassword.isNullOrBlank() &&
            !releaseKeyAlias.isNullOrBlank() &&
            !releaseKeyPassword.isNullOrBlank()
        ) {
            create("release") {
                storeFile = file(releaseKeystorePath)
                storePassword = releaseKeystorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        debug {
            buildConfigField("String", "CHATNU_API_URL", q(System.getenv("CHATNU_API_URL") ?: "http://10.0.2.2:3000/"))
            buildConfigField("String", "CHATNU_WS_URL", q(System.getenv("CHATNU_WS_URL") ?: "ws://10.0.2.2:3000/realtime"))
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("String", "CHATNU_API_URL", q(System.getenv("CHATNU_API_URL") ?: "https://api.devnu.ir/"))
            buildConfigField("String", "CHATNU_WS_URL", q(System.getenv("CHATNU_WS_URL") ?: "wss://api.devnu.ir/realtime"))
            signingConfigs.findByName("release")?.let { signingConfig = it }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources.excludes += setOf("/META-INF/{AL2.0,LGPL2.1}")
    }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.09.00"))
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-core")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.room:room-runtime:2.7.0")
    implementation("androidx.room:room-ktx:2.7.0")
    implementation("io.coil-kt:coil-compose:2.7.0")
    implementation("com.squareup.retrofit2:retrofit:2.12.0")
    implementation("com.squareup.retrofit2:converter-moshi:2.12.0")
    implementation("com.squareup.moshi:moshi-kotlin:1.15.2")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("com.google.firebase:firebase-messaging:25.0.1")
    implementation("io.github.webrtc-sdk:android:144.7559.12")

    testImplementation("junit:junit:4.13.2")
    debugImplementation("androidx.compose.ui:ui-tooling")
}

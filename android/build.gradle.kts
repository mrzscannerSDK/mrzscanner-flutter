// The Flutter plugin's Android side: MrzscannerPlugin over the MRZ scanner's Android SDK
// (com.barkoder.mrzscanner:mrzscanner-ar, shipped in maven/ inside this package).
group = "com.mrzscanner.flutter"
version = "2.7.4"
val mrzscannerVersion = "2.7.4"

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
    }
}

// The MRZ scanner SDK, for every project of the app: the app resolves this module's dependencies
// with its own repositories.
val mrzscannerMaven = file("maven")
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.allprojects {
    repositories {
        maven { url = uri(mrzscannerMaven) }
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.mrzscanner.flutter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        minSdk = 24
    }
}

dependencies {
    implementation("com.barkoder.mrzscanner:mrzscanner-ar:$mrzscannerVersion")
}

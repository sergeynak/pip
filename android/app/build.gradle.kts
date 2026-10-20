plugins {
    id("com.android.application")
    // Плагин Flutter подключается после плагинов Android и Kotlin.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "kz.pip.pip"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Уникальное имя приложения в Android.
        applicationId = "kz.pip.pip"
        // Поддерживаемые версии Android берём из настроек Flutter.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Номер и название версии задаются в pubspec.yaml.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Пока используется отладочная подпись. Перед публикацией в магазине
            // здесь нужно настроить собственный ключ подписи приложения.
            signingConfig = signingConfigs.getByName("debug")
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

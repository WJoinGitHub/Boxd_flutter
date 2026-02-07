import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 读取 key.properties（用于 Google Play 发布签名）
// key.properties 在 android/ 下；storeFile 路径相对 android/app/ 解析（与 Flutter 文档一致）
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
val releaseStoreFile = keystoreProperties["storeFile"]?.toString()?.let { project.file(it) }
val hasValidReleaseSigning = keystorePropertiesFile.exists() &&
    releaseStoreFile != null &&
    releaseStoreFile.exists() &&
    keystoreProperties["keyAlias"] != null &&
    keystoreProperties["storePassword"] != null &&
    keystoreProperties["keyPassword"] != null

android {
    namespace = "com.qimi.heatlink"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            if (hasValidReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = releaseStoreFile
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        applicationId = "com.qimi.heatlink"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasValidReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                if (keystorePropertiesFile.exists()) {
                    throw GradleException(
                        "Release 签名配置无效。请检查 android/key.properties：" +
                        " storeFile 指向的 keystore 是否存在？" +
                        " keystore 在 android/ 下时 storeFile 填 ../upload-keystore.jks"
                    )
                } else {
                    throw GradleException(
                        "Release 构建需要签名。请复制 android/key.properties.example 为 android/key.properties，" +
                        "填写 keystore 路径（storeFile=../upload-keystore.jks）、密码和 keyAlias。"
                    )
                }
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

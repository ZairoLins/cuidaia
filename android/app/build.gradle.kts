import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val chaveRelease = rootProject.file("key.properties")
val propsChave = Properties().apply {
    if (chaveRelease.exists()) chaveRelease.inputStream().use { load(it) }
}

android {
    namespace = "br.com.cuidaia.app"
    // flutter_local_notifications 23 exige compileSdk 37.
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Necessário para agendar notificações (flutter_local_notifications).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "br.com.cuidaia.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Chave de upload em android/key.properties + app/upload-keystore.jks (fora do git).
    // Sem esses arquivos, o build de release é recusado (veja o fim deste arquivo).
    signingConfigs {
        if (chaveRelease.exists()) {
            create("release") {
                keyAlias = propsChave.getProperty("keyAlias")
                keyPassword = propsChave.getProperty("keyPassword")
                storeFile = file(propsChave.getProperty("storeFile"))
                storePassword = propsChave.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                if (chaveRelease.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Um release assinado com a chave de debug instala, mas não serve para
// distribuir: o login com Google e o Play Integrity dependem da chave certa.
// Por isso, sem a chave de upload, o build de release para com um aviso claro
// em vez de gerar um pacote que parece pronto.
gradle.taskGraph.whenReady {
    val pedeRelease = allTasks.any {
        it.project == project && (it.name.startsWith("assemble") || it.name.startsWith("bundle")) &&
            it.name.endsWith("Release")
    }
    if (pedeRelease && !chaveRelease.exists()) {
        throw GradleException(
            "Build de release sem chave de assinatura: crie android/key.properties e " +
                "android/app/upload-keystore.jks (veja docs/publicacao.md). " +
                "Para testar sem a chave, use o modo debug (flutter run / flutter build apk --debug)."
        )
    }
}

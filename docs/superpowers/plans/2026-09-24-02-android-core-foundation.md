# Plan 2 of 3 — Android Core Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the Android project (single `:app` module) with dev/staging/prod flavors, config loading, networking + auth + error handling, logging + crash reporting, adaptive/orientation rules and the non-visual MVVM core (`LoadState`, `UiEffect`, `BaseViewModel.launchSubmit`), all unit tested.

**Architecture:** Package `com.noshitechinc.restaurant` with `core/common`, `core/logging`, `core/network`, `core/auth`, `core/adaptive`, `core/ui`, `data/`, `di/`, `app/`. Pure logic is JVM-unit-tested; Android glue (Keystore, ConnectivityManager, Firebase) sits behind interfaces with fakes.

**Tech Stack:** AGP 9.0.1 (built-in Kotlin 2.2.10), Gradle 9.2.1, JDK 21, Compose BOM 2025.07.00, Hilt 2.56, Retrofit 2.11 + kotlinx.serialization, OkHttp 4.12, DataStore 1.1.1, Timber 5.0.1, Firebase BOM 34.1.0 (Crashlytics), ktlint-gradle 14.2.0 (ktlint 1.8.0), detekt 2.0.0-alpha.3, JUnit4, kotlin-test, MockK, Turbine, coroutines-test, MockWebServer.

**Spec:** `docs/superpowers/specs/2026-09-24-android-foundation-design.md` §3–6, §8 (orientation), §10, §14.

## Global Constraints

- Code repo root: `/home/bs01470/AndroidStudioProjects/resturant-app`. Source root: `app/src/main/java/com/noshitechinc/restaurant/` (abbreviated `SRC/`); tests: `app/src/test/java/com/noshitechinc/restaurant/` (`TEST/`).
- No git commands. "Checkpoint" = list changed files.
- Gradle commands are run with `ANDROID_HOME=$HOME/Android/Sdk` prefixed (the agent must not create or read `local.properties`; the guard hook blocks it).
- minSdk 25, targetSdk 36, compileSdk 36, Java 21 source/target.
- No hardcoded user-facing strings in Kotlin; English strings in `res/values/strings.xml`.
- ViewModels never import `android.content.Context` or `androidx.compose.*`.
- Never log tokens; `Authorization`, `Cookie`, `Set-Cookie` redacted in HTTP logs.
- Comments only for non-obvious constraints.

---

### Task 1: Gradle project, flavors, config, manifest, app shell

**Files:**
- Create: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`, `.editorconfig`
- Copy from `/home/bs01470/AndroidStudioProjects/butterfly-complete-project/butterfly-mobile-android`: `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, `gradle/wrapper/gradle-wrapper.properties` (9.2.1), `gradle/gradle-daemon-jvm.properties` (toolchainVersion=21)
- Create: `config/env/dev.properties`, `config/env/staging.properties`, `config/env/prod.properties`, `local.properties.example`
- Create: `app/build.gradle.kts`, `app/proguard-rules.pro`
- Create: `app/src/main/AndroidManifest.xml`
- Create: `app/src/main/res/values/strings.xml`, `values/colors.xml`, `values/themes.xml`
- Create: `app/src/main/res/drawable/ic_launcher_foreground.xml`, `drawable/ic_launcher.xml`, `drawable-anydpi-v26/ic_launcher.xml`
- Create: `SRC/app/RestaurantApplication.kt`, `SRC/app/MainActivity.kt`
- Modify: `.gitignore` (append Android entries)

**Interfaces:**
- Produces `BuildConfig` fields: `ENVIRONMENT: String` (`dev|staging|prod`), `API_BASE_URL: String`, `HTTP_LOG_LEVEL: String` (`NONE|BASIC|HEADERS|BODY`), `CRASH_REPORTING_ENABLED: Boolean`, `CONNECT_TIMEOUT_SECONDS: Long`, `READ_TIMEOUT_SECONDS: Long`; resource `R.string.app_name`; manifest placeholder `crashlyticsCollectionEnabled`.

- [ ] **Step 1: Copy wrapper files**

Run:
```bash
cd /home/bs01470/AndroidStudioProjects/resturant-app
REF=/home/bs01470/AndroidStudioProjects/butterfly-complete-project/butterfly-mobile-android
mkdir -p gradle/wrapper
cp "$REF/gradlew" "$REF/gradlew.bat" .
cp "$REF/gradle/wrapper/gradle-wrapper.jar" "$REF/gradle/wrapper/gradle-wrapper.properties" gradle/wrapper/
cp "$REF/gradle/gradle-daemon-jvm.properties" gradle/
chmod +x gradlew
rg distributionUrl gradle/wrapper/gradle-wrapper.properties
```
Expected: `distributionUrl=https\://services.gradle.org/distributions/gradle-9.2.1-bin.zip`

- [ ] **Step 2: `settings.gradle.kts`**

```kotlin
pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "NoshitechRestaurant"
include(":app")
```

- [ ] **Step 3: `gradle/libs.versions.toml`**

```toml
[versions]
agp = "9.0.1"
kotlin = "2.2.10"
ksp = "2.3.2"
coreKtx = "1.17.0"
activityCompose = "1.9.3"
lifecycle = "2.8.7"
composeBom = "2025.07.00"
navigationCompose = "2.8.5"
hilt = "2.56"
hiltNavigationCompose = "1.2.0"
retrofit = "2.11.0"
okhttp = "4.12.0"
kotlinxSerialization = "1.8.0"
coroutines = "1.9.0"
datastore = "1.1.1"
splashscreen = "1.0.1"
coil = "3.3.0"
timber = "5.0.1"
firebaseBom = "34.1.0"
googleServices = "4.4.2"
firebaseCrashlyticsPlugin = "3.0.8"
ktlintGradle = "14.2.0"
ktlint = "1.8.0"
detekt = "2.0.0-alpha.3"
junit = "4.13.2"
mockk = "1.13.13"
turbine = "1.2.0"
androidxTestExtJunit = "1.2.1"
androidxTestRunner = "1.6.2"
espresso = "3.6.1"

[libraries]
androidx-core-ktx = { group = "androidx.core", name = "core-ktx", version.ref = "coreKtx" }
androidx-core-splashscreen = { group = "androidx.core", name = "core-splashscreen", version.ref = "splashscreen" }
androidx-activity-compose = { group = "androidx.activity", name = "activity-compose", version.ref = "activityCompose" }
androidx-lifecycle-runtime-ktx = { group = "androidx.lifecycle", name = "lifecycle-runtime-ktx", version.ref = "lifecycle" }
androidx-lifecycle-runtime-compose = { group = "androidx.lifecycle", name = "lifecycle-runtime-compose", version.ref = "lifecycle" }
androidx-lifecycle-viewmodel-compose = { group = "androidx.lifecycle", name = "lifecycle-viewmodel-compose", version.ref = "lifecycle" }
androidx-compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "composeBom" }
androidx-compose-ui = { group = "androidx.compose.ui", name = "ui" }
androidx-compose-ui-graphics = { group = "androidx.compose.ui", name = "ui-graphics" }
androidx-compose-ui-tooling = { group = "androidx.compose.ui", name = "ui-tooling" }
androidx-compose-ui-tooling-preview = { group = "androidx.compose.ui", name = "ui-tooling-preview" }
androidx-compose-ui-test-junit4 = { group = "androidx.compose.ui", name = "ui-test-junit4" }
androidx-compose-ui-test-manifest = { group = "androidx.compose.ui", name = "ui-test-manifest" }
androidx-compose-material3 = { group = "androidx.compose.material3", name = "material3" }
androidx-compose-material-icons-extended = { group = "androidx.compose.material", name = "material-icons-extended" }
androidx-navigation-compose = { group = "androidx.navigation", name = "navigation-compose", version.ref = "navigationCompose" }
androidx-datastore-preferences = { group = "androidx.datastore", name = "datastore-preferences", version.ref = "datastore" }
hilt-android = { group = "com.google.dagger", name = "hilt-android", version.ref = "hilt" }
hilt-compiler = { group = "com.google.dagger", name = "hilt-android-compiler", version.ref = "hilt" }
hilt-navigation-compose = { group = "androidx.hilt", name = "hilt-navigation-compose", version.ref = "hiltNavigationCompose" }
retrofit = { group = "com.squareup.retrofit2", name = "retrofit", version.ref = "retrofit" }
retrofit-converter-kotlinx-serialization = { group = "com.squareup.retrofit2", name = "converter-kotlinx-serialization", version.ref = "retrofit" }
okhttp = { group = "com.squareup.okhttp3", name = "okhttp", version.ref = "okhttp" }
okhttp-logging-interceptor = { group = "com.squareup.okhttp3", name = "logging-interceptor", version.ref = "okhttp" }
okhttp-mockwebserver = { group = "com.squareup.okhttp3", name = "mockwebserver", version.ref = "okhttp" }
kotlinx-serialization-json = { group = "org.jetbrains.kotlinx", name = "kotlinx-serialization-json", version.ref = "kotlinxSerialization" }
kotlinx-coroutines-android = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-android", version.ref = "coroutines" }
kotlinx-coroutines-test = { group = "org.jetbrains.kotlinx", name = "kotlinx-coroutines-test", version.ref = "coroutines" }
coil-compose = { group = "io.coil-kt.coil3", name = "coil-compose", version.ref = "coil" }
coil-network-okhttp = { group = "io.coil-kt.coil3", name = "coil-network-okhttp", version.ref = "coil" }
timber = { group = "com.jakewharton.timber", name = "timber", version.ref = "timber" }
firebase-bom = { group = "com.google.firebase", name = "firebase-bom", version.ref = "firebaseBom" }
firebase-crashlytics = { group = "com.google.firebase", name = "firebase-crashlytics" }
junit = { group = "junit", name = "junit", version.ref = "junit" }
kotlin-test-junit = { group = "org.jetbrains.kotlin", name = "kotlin-test-junit", version.ref = "kotlin" }
mockk = { group = "io.mockk", name = "mockk", version.ref = "mockk" }
turbine = { group = "app.cash.turbine", name = "turbine", version.ref = "turbine" }
androidx-test-ext-junit = { group = "androidx.test.ext", name = "junit", version.ref = "androidxTestExtJunit" }
androidx-test-runner = { group = "androidx.test", name = "runner", version.ref = "androidxTestRunner" }
androidx-espresso-core = { group = "androidx.test.espresso", name = "espresso-core", version.ref = "espresso" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
hilt = { id = "com.google.dagger.hilt.android", version.ref = "hilt" }
google-services = { id = "com.google.gms.google-services", version.ref = "googleServices" }
firebase-crashlytics = { id = "com.google.firebase.crashlytics", version.ref = "firebaseCrashlyticsPlugin" }
ktlint = { id = "org.jlleitschuh.gradle.ktlint", version.ref = "ktlintGradle" }
detekt = { id = "dev.detekt", version.ref = "detekt" }
```

- [ ] **Step 4: root `build.gradle.kts`**

```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
    alias(libs.plugins.hilt) apply false
    alias(libs.plugins.google.services) apply false
    alias(libs.plugins.firebase.crashlytics) apply false
    alias(libs.plugins.ktlint) apply false
    alias(libs.plugins.detekt) apply false
}
```

- [ ] **Step 5: `gradle.properties`** (AGP 9 compatibility flags copied from Butterfly, which builds with this exact AGP/Kotlin/Hilt/KSP combination)

```properties
org.gradle.jvmargs=-Xmx4096m -Dfile.encoding=UTF-8
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configuration-cache=false
android.useAndroidX=true
kotlin.code.style=official
android.nonTransitiveRClass=true
android.builtInKotlin=true
android.newDsl=false
android.disallowKotlinSourceSets=false
android.sdk.defaultTargetSdkToCompileSdkIfUnset=false
android.enableAppCompileTimeRClass=false
android.usesSdkInManifest.disallowed=false
android.uniquePackageNames=false
android.dependency.useConstraints=true
android.r8.strictFullModeForKeepRules=false
android.r8.optimizedResourceShrinking=false
```

- [ ] **Step 6: `.editorconfig`**

```editorconfig
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{kt,kts}]
ktlint_code_style = android_studio
max_line_length = 140
ktlint_function_naming_ignore_when_annotated_with = Composable
ktlint_standard_filename = disabled
ktlint_standard_property-naming = disabled
ij_kotlin_allow_trailing_comma = true
ij_kotlin_allow_trailing_comma_on_call_site = true

[*.{json,yml,yaml,xml,toml}]
indent_size = 2
```

- [ ] **Step 7: Environment config files**

`config/env/dev.properties`
```properties
APP_NAME=Noshitech Restaurant (Dev)
APPLICATION_ID_SUFFIX=.dev
API_BASE_URL=https://api.dev.noshitech.invalid/
HTTP_LOG_LEVEL=BODY
CRASH_REPORTING_ENABLED=false
CONNECT_TIMEOUT_SECONDS=20
READ_TIMEOUT_SECONDS=30
```
`config/env/staging.properties`
```properties
APP_NAME=Noshitech Restaurant (Staging)
APPLICATION_ID_SUFFIX=.staging
API_BASE_URL=https://api.staging.noshitech.invalid/
HTTP_LOG_LEVEL=HEADERS
CRASH_REPORTING_ENABLED=true
CONNECT_TIMEOUT_SECONDS=20
READ_TIMEOUT_SECONDS=30
```
`config/env/prod.properties`
```properties
APP_NAME=Noshitech Restaurant
APPLICATION_ID_SUFFIX=
API_BASE_URL=https://api.noshitech.invalid/
HTTP_LOG_LEVEL=NONE
CRASH_REPORTING_ENABLED=true
CONNECT_TIMEOUT_SECONDS=20
READ_TIMEOUT_SECONDS=30
```
`local.properties.example`
```properties
sdk.dir=/path/to/Android/Sdk
KEYSTORE_PATH=/path/to/release.jks
KEYSTORE_PASSWORD=
KEY_ALIAS=
KEY_PASSWORD=
```

- [ ] **Step 8: `app/build.gradle.kts`**

```kotlin
import com.android.build.api.dsl.ApplicationExtension
import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
    alias(libs.plugins.hilt)
    alias(libs.plugins.ktlint)
    alias(libs.plugins.detekt)
}

val environments = listOf("dev", "staging", "prod")

fun loadProperties(path: String): Properties = Properties().apply {
    val file = rootProject.file(path)
    if (file.exists()) file.inputStream().use(::load)
}

val localProperties = loadProperties("local.properties")

fun secret(key: String): String? = System.getenv(key)?.takeIf { it.isNotBlank() }
    ?: localProperties.getProperty(key)?.trim()?.takeIf { it.isNotEmpty() }

fun envConfig(name: String): Properties = loadProperties("config/env/$name.properties").also {
    require(!it.isEmpty) { "Missing config/env/$name.properties" }
}

val firebaseConfigured = environments.any { file("src/$it/google-services.json").exists() }
if (firebaseConfigured) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
}

val releaseSigning = listOf("KEYSTORE_PATH", "KEYSTORE_PASSWORD", "KEY_ALIAS", "KEY_PASSWORD").associateWith(::secret)
val hasReleaseSigning = releaseSigning.values.all { it != null }

extensions.configure<ApplicationExtension> {
    namespace = "com.noshitechinc.restaurant"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.noshitechinc.restaurant"
        minSdk = 25
        targetSdk = 36
        versionCode = 1
        versionName = "0.1.0"
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseSigning.getValue("KEYSTORE_PATH")!!)
                storePassword = releaseSigning.getValue("KEYSTORE_PASSWORD")
                keyAlias = releaseSigning.getValue("KEY_ALIAS")
                keyPassword = releaseSigning.getValue("KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            isPseudoLocalesEnabled = true
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            if (hasReleaseSigning) signingConfig = signingConfigs.getByName("release")
        }
    }

    flavorDimensions += "environment"
    productFlavors {
        environments.forEach { env ->
            create(env) {
                dimension = "environment"
                val config = envConfig(env)
                fun value(key: String): String =
                    requireNotNull(config.getProperty(key)) { "$key missing in config/env/$env.properties" }.trim()
                value("APPLICATION_ID_SUFFIX").takeIf { it.isNotEmpty() }?.let { applicationIdSuffix = it }
                resValue("string", "app_name", value("APP_NAME"))
                buildConfigField("String", "ENVIRONMENT", "\"$env\"")
                buildConfigField("String", "API_BASE_URL", "\"${value("API_BASE_URL")}\"")
                buildConfigField("String", "HTTP_LOG_LEVEL", "\"${value("HTTP_LOG_LEVEL")}\"")
                buildConfigField("boolean", "CRASH_REPORTING_ENABLED", value("CRASH_REPORTING_ENABLED"))
                buildConfigField("long", "CONNECT_TIMEOUT_SECONDS", "${value("CONNECT_TIMEOUT_SECONDS")}L")
                buildConfigField("long", "READ_TIMEOUT_SECONDS", "${value("READ_TIMEOUT_SECONDS")}L")
                manifestPlaceholders["crashlyticsCollectionEnabled"] = value("CRASH_REPORTING_ENABLED")
            }
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    buildFeatures {
        compose = true
        buildConfig = true
        resValues = true
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }

    lint {
        abortOnError = true
    }
}

ktlint {
    version.set(libs.versions.ktlint.get())
    android.set(true)
}

detekt {
    buildUponDefaultConfig = true
    config.setFrom(rootProject.file("config/detekt/detekt.yml"))
    source.setFrom("src/main/java", "src/test/java", "src/androidTest/java")
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.core.splashscreen)
    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.lifecycle.viewmodel.compose)

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.navigation.compose)

    implementation(libs.hilt.android)
    ksp(libs.hilt.compiler)
    implementation(libs.hilt.navigation.compose)

    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.kotlinx.serialization)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging.interceptor)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.androidx.datastore.preferences)
    implementation(libs.coil.compose)
    implementation(libs.coil.network.okhttp)
    implementation(libs.timber)
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.crashlytics)

    testImplementation(libs.junit)
    testImplementation(libs.kotlin.test.junit)
    testImplementation(libs.mockk)
    testImplementation(libs.turbine)
    testImplementation(libs.kotlinx.coroutines.test)
    testImplementation(libs.okhttp.mockwebserver)

    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.runner)
    androidTestImplementation(libs.androidx.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)
}
```

Also create `config/detekt/detekt.yml` now (Task 8 tunes it):

```yaml
naming:
  FunctionNaming:
    ignoreAnnotated: ['Composable']
complexity:
  LongParameterList:
    functionThreshold: 8
    ignoreDefaultParameters: true
    ignoreAnnotated: ['Composable']
  LongMethod:
    ignoreAnnotated: ['Composable']
style:
  MagicNumber:
    ignorePropertyDeclaration: true
    ignoreCompanionObjectPropertyDeclaration: true
    ignoreAnnotated: ['Composable']
    excludes: ['**/test/**', '**/androidTest/**', '**/core/designsystem/theme/**', '**/core/designsystem/preview/**']
```

- [ ] **Step 9: `app/proguard-rules.pro`**

```proguard
-keepattributes Signature, InnerClasses, EnclosingMethod, *Annotation*
-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
-keepclassmembers @kotlinx.serialization.Serializable class com.noshitechinc.restaurant.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
```

- [ ] **Step 10: Manifest** `app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

    <application
        android:name=".app.RestaurantApplication"
        android:allowBackup="false"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@drawable/ic_launcher"
        android:supportsRtl="true"
        android:theme="@style/Theme.NoshitechRestaurant">

        <property
            android:name="android.window.PROPERTY_COMPAT_ALLOW_RESTRICTED_RESIZABILITY"
            android:value="true" />

        <meta-data
            android:name="firebase_crashlytics_collection_enabled"
            android:value="${crashlyticsCollectionEnabled}" />

        <activity
            android:name=".app.MainActivity"
            android:exported="true"
            android:theme="@style/Theme.NoshitechRestaurant.Splash"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

- [ ] **Step 11: Resources**

`values/strings.xml`
```xml
<resources>
    <string name="home_title">Welcome</string>
</resources>
```
`values/colors.xml`
```xml
<resources>
    <color name="window_background">#FFF8F7F5</color>
    <color name="splash_background">#FFFFFFFF</color>
    <color name="ic_launcher_background">#FFC2410C</color>
</resources>
```
`values/themes.xml`
```xml
<resources>
    <style name="Theme.NoshitechRestaurant" parent="android:Theme.Material.Light.NoActionBar">
        <item name="android:windowBackground">@color/window_background</item>
    </style>

    <style name="Theme.NoshitechRestaurant.Splash" parent="Theme.SplashScreen">
        <item name="windowSplashScreenBackground">@color/splash_background</item>
        <item name="windowSplashScreenAnimatedIcon">@drawable/ic_launcher_foreground</item>
        <item name="postSplashScreenTheme">@style/Theme.NoshitechRestaurant</item>
    </style>
</resources>
```
`drawable/ic_launcher_foreground.xml`
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path android:fillColor="#FFFFFFFF" android:pathData="M54,30a24,24 0,1 1,0 48a24,24 0,1 1,0 -48z" />
    <path android:fillColor="#FFC2410C" android:pathData="M54,38a16,16 0,1 1,0 32a16,16 0,1 1,0 -32z" />
    <path android:fillColor="#FFFFFFFF" android:pathData="M54,44a10,10 0,1 1,0 20a10,10 0,1 1,0 -20z" />
</vector>
```
`drawable/ic_launcher.xml`
```xml
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="oval">
            <solid android:color="@color/ic_launcher_background" />
        </shape>
    </item>
    <item android:drawable="@drawable/ic_launcher_foreground" />
</layer-list>
```
`drawable-anydpi-v26/ic_launcher.xml`
```xml
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
```

- [ ] **Step 12: App shell** (Plan 3 Task 9 replaces `MainActivity` content)

`SRC/app/RestaurantApplication.kt`
```kotlin
package com.noshitechinc.restaurant.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class RestaurantApplication : Application()
```
`SRC/app/MainActivity.kt`
```kotlin
package com.noshitechinc.restaurant.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.ui.res.stringResource
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.noshitechinc.restaurant.R
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MaterialTheme {
                Text(text = stringResource(R.string.home_title))
            }
        }
    }
}
```

- [ ] **Step 13: Append to `.gitignore`**

```gitignore
.gradle/
.kotlin/
build/
/local.properties
/captures
.externalNativeBuild
.cxx
*.iml
.idea/
.DS_Store
*.jks
*.keystore
app/src/*/google-services.json
*.env
```

- [ ] **Step 14: Build all three flavors**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew assembleDevDebug assembleStagingDebug assembleProdRelease --console=plain`
Expected: `BUILD SUCCESSFUL`. If plugin resolution fails for detekt (`dev.detekt` 2.0.0-alpha.3) or it throws during configuration: remove `alias(libs.plugins.detekt)` from both build files and the `detekt {}` block, keep the catalog entry, record the failure text under PDR-005 in the context repo, and continue (Task 8 re-evaluates).

- [ ] **Step 15: Verify flavor identity and config**

Run:
```bash
cd /home/bs01470/AndroidStudioProjects/resturant-app
AAPT2=$HOME/Android/Sdk/build-tools/36.0.0/aapt2
for apk in app/build/outputs/apk/dev/debug/app-dev-debug.apk app/build/outputs/apk/staging/debug/app-staging-debug.apk app/build/outputs/apk/prod/release/app-prod-release-unsigned.apk; do "$AAPT2" dump badging "$apk" | rg -o "package: name='[^']+'|application-label:'[^']+'"; done
rg -n "API_BASE_URL|ENVIRONMENT|CRASH_REPORTING_ENABLED" app/build/generated/source/buildConfig/dev/debug/com/noshitechinc/restaurant/BuildConfig.java
```
Expected: `com.noshitechinc.restaurant.dev` / `Noshitech Restaurant (Dev)`, `com.noshitechinc.restaurant.staging` / `Noshitech Restaurant (Staging)`, `com.noshitechinc.restaurant` / `Noshitech Restaurant`; BuildConfig shows `https://api.dev.noshitech.invalid/`, `"dev"`, `false`.

- [ ] **Step 16: Checkpoint** — list files. Update context repo `docs/05-breakdown/sprints/sprint-0.md`: FOUND-001, FOUND-002 → In progress.

---

### Task 2: `core/common` — results, errors, text, app info, market formatting, validation

**Files:**
- Create: `SRC/core/common/AppError.kt`, `ApiResult.kt`, `UiText.kt`, `AppInfo.kt`
- Create: `SRC/core/common/coroutines/Qualifiers.kt`
- Create: `SRC/core/common/market/MarketConfig.kt`
- Create: `SRC/core/common/format/CurrencyFormatter.kt`, `SRC/core/common/format/UsPhoneFormatter.kt`
- Create: `SRC/core/common/model/PostalAddress.kt`
- Create: `SRC/core/common/validation/UsPhoneValidator.kt`, `SRC/core/common/validation/UsAddressValidator.kt`
- Create: `SRC/di/AppModule.kt`, `SRC/di/CoroutinesModule.kt`
- Test: `TEST/core/common/ApiResultTest.kt`, `TEST/core/common/format/CurrencyFormatterTest.kt`, `TEST/core/common/format/UsPhoneFormatterTest.kt`, `TEST/core/common/validation/ValidatorsTest.kt`

**Interfaces (Produces):**
- `sealed interface AppError { NoInternet; Timeout; ServiceUnavailable; SessionExpired; Forbidden; NotFound; Validation(message: String?, fieldErrors: Map<String, List<String>>); Server(code: Int, message: String?); Unknown(cause: Throwable?) }`
- `sealed interface ApiResult<out T> { Success(data: T); Failure(error: AppError) }` + `map`, `onSuccess`, `onFailure`
- `sealed interface UiText { Resource(@StringRes id: Int, args: List<Any>); Dynamic(value: String) }`
- `enum class AppEnvironment { Dev, Staging, Prod }`, `data class AppInfo(environment: AppEnvironment, versionName: String, versionCode: Int)`
- Qualifiers `@IoDispatcher`, `@DefaultDispatcher`, `@ApplicationScope`
- `data class MarketConfig(locale, currencyCode, phoneCountryCode, phoneNationalDigits)` with `MarketConfig.UnitedStates`
- `class CurrencyFormatter(market)`: `format(cents: Long): String`, `formatAmount(cents: Long): String`, `companion centsFromDigits(input: String): Long`, `MAX_DIGITS = 11`
- `object UsPhoneFormatter`: `digitsOnly(input): String`, `format(digits): String`, `originalToTransformed(offset, digitCount): Int`, `transformedToOriginal(offset, digitCount): Int`, `NATIONAL_DIGITS = 10`
- `data class PostalAddress(street, unit, city, state, zip)`, `enum class AddressField { Street, City, State, Zip }`
- `object UsPhoneValidator { isValid(digits): Boolean }`, `object UsAddressValidator { invalidFields(address): Set<AddressField> }`

- [ ] **Step 1: Write failing tests**

`TEST/core/common/ApiResultTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.common

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ApiResultTest {
    @Test
    fun `map transforms success data`() {
        val result: ApiResult<Int> = ApiResult.Success(2)
        assertEquals(ApiResult.Success(4), result.map { it * 2 })
    }

    @Test
    fun `map keeps failure untouched`() {
        val result: ApiResult<Int> = ApiResult.Failure(AppError.NotFound)
        assertEquals(ApiResult.Failure(AppError.NotFound), result.map { it * 2 })
    }

    @Test
    fun `onFailure runs only for failures`() {
        var seen: AppError? = null
        ApiResult.Success(1).onFailure { seen = it }
        assertEquals(null, seen)
        ApiResult.Failure(AppError.Timeout).onFailure { seen = it }
        assertTrue(seen is AppError.Timeout)
    }
}
```

`TEST/core/common/format/CurrencyFormatterTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.format

import kotlin.test.Test
import kotlin.test.assertEquals

class CurrencyFormatterTest {
    private val formatter = CurrencyFormatter()

    @Test
    fun `formats cents as US dollars`() {
        assertEquals("$1,234.56", formatter.format(123_456))
        assertEquals("$0.00", formatter.format(0))
        assertEquals("$0.05", formatter.format(5))
    }

    @Test
    fun `formats amount without currency symbol`() {
        assertEquals("1,234.56", formatter.formatAmount(123_456))
    }

    @Test
    fun `parses typed digits into cents`() {
        assertEquals(123L, CurrencyFormatter.centsFromDigits("1a2b3"))
        assertEquals(0L, CurrencyFormatter.centsFromDigits("000"))
        assertEquals(0L, CurrencyFormatter.centsFromDigits(""))
    }

    @Test
    fun `caps digits to avoid overflow`() {
        assertEquals(99_999_999_999L, CurrencyFormatter.centsFromDigits("9".repeat(30)))
    }
}
```

`TEST/core/common/format/UsPhoneFormatterTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.format

import kotlin.test.Test
import kotlin.test.assertEquals

class UsPhoneFormatterTest {
    @Test
    fun `keeps at most ten digits`() {
        assertEquals("5551234567", UsPhoneFormatter.digitsOnly("(555) 123-4567 ext 89"))
    }

    @Test
    fun `formats progressively while typing`() {
        assertEquals("", UsPhoneFormatter.format(""))
        assertEquals("(55", UsPhoneFormatter.format("55"))
        assertEquals("(555) 12", UsPhoneFormatter.format("55512"))
        assertEquals("(555) 123-4567", UsPhoneFormatter.format("5551234567"))
    }

    @Test
    fun `offset mapping round trips at every digit boundary`() {
        val digits = "5551234567"
        for (count in 0..digits.length) {
            val formatted = UsPhoneFormatter.format(digits.take(count))
            for (offset in 0..count) {
                val transformed = UsPhoneFormatter.originalToTransformed(offset, count)
                assert(transformed in 0..formatted.length) { "offset $offset/$count -> $transformed" }
                assertEquals(offset, UsPhoneFormatter.transformedToOriginal(transformed, count))
            }
        }
    }
}
```

`TEST/core/common/validation/ValidatorsTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.validation

import com.noshitechinc.restaurant.core.common.model.PostalAddress
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ValidatorsTest {
    @Test
    fun `accepts valid US phone numbers`() {
        assertTrue(UsPhoneValidator.isValid("5552345678"))
    }

    @Test
    fun `rejects short numbers and invalid area or exchange codes`() {
        assertFalse(UsPhoneValidator.isValid("555234567"))
        assertFalse(UsPhoneValidator.isValid("1552345678"))
        assertFalse(UsPhoneValidator.isValid("5551345678"))
    }

    @Test
    fun `valid address has no invalid fields`() {
        val address = PostalAddress(street = "1 Main St", city = "Austin", state = "TX", zip = "73301")
        assertEquals(emptySet(), UsAddressValidator.invalidFields(address))
    }

    @Test
    fun `reports each invalid field`() {
        val address = PostalAddress(street = " ", city = "", state = "Texas", zip = "7330")
        assertEquals(AddressField.entries.toSet(), UsAddressValidator.invalidFields(address))
    }

    @Test
    fun `accepts ZIP plus four`() {
        val address = PostalAddress(street = "1 Main St", city = "Austin", state = "tx", zip = "73301-1234")
        assertEquals(emptySet(), UsAddressValidator.invalidFields(address))
    }
}
```

- [ ] **Step 2: Run tests — expect compilation failure**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest --console=plain`
Expected: FAIL — unresolved references (`ApiResult`, `CurrencyFormatter`, …).

- [ ] **Step 3: Implement**

`SRC/core/common/AppError.kt`
```kotlin
package com.noshitechinc.restaurant.core.common

sealed interface AppError {
    data object NoInternet : AppError
    data object Timeout : AppError
    data object ServiceUnavailable : AppError
    data object SessionExpired : AppError
    data object Forbidden : AppError
    data object NotFound : AppError
    data class Validation(val message: String?, val fieldErrors: Map<String, List<String>> = emptyMap()) : AppError
    data class Server(val code: Int, val message: String?) : AppError
    data class Unknown(val cause: Throwable? = null) : AppError
}
```

`SRC/core/common/ApiResult.kt`
```kotlin
package com.noshitechinc.restaurant.core.common

sealed interface ApiResult<out T> {
    data class Success<out T>(val data: T) : ApiResult<T>
    data class Failure(val error: AppError) : ApiResult<Nothing>
}

inline fun <T, R> ApiResult<T>.map(transform: (T) -> R): ApiResult<R> = when (this) {
    is ApiResult.Success -> ApiResult.Success(transform(data))
    is ApiResult.Failure -> this
}

inline fun <T> ApiResult<T>.onSuccess(action: (T) -> Unit): ApiResult<T> {
    if (this is ApiResult.Success) action(data)
    return this
}

inline fun <T> ApiResult<T>.onFailure(action: (AppError) -> Unit): ApiResult<T> {
    if (this is ApiResult.Failure) action(error)
    return this
}
```

`SRC/core/common/UiText.kt`
```kotlin
package com.noshitechinc.restaurant.core.common

import androidx.annotation.StringRes

sealed interface UiText {
    data class Resource(@StringRes val id: Int, val args: List<Any> = emptyList()) : UiText
    data class Dynamic(val value: String) : UiText
}
```

`SRC/core/common/AppInfo.kt`
```kotlin
package com.noshitechinc.restaurant.core.common

enum class AppEnvironment {
    Dev,
    Staging,
    Prod,
    ;

    companion object {
        fun from(value: String): AppEnvironment = entries.first { it.name.equals(value, ignoreCase = true) }
    }
}

data class AppInfo(
    val environment: AppEnvironment,
    val versionName: String,
    val versionCode: Int,
)
```

`SRC/core/common/coroutines/Qualifiers.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.coroutines

import javax.inject.Qualifier

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class IoDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class DefaultDispatcher

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class ApplicationScope
```

`SRC/core/common/market/MarketConfig.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.market

import java.util.Locale

data class MarketConfig(
    val locale: Locale,
    val currencyCode: String,
    val phoneCountryCode: String,
    val phoneNationalDigits: Int,
) {
    companion object {
        val UnitedStates = MarketConfig(
            locale = Locale.US,
            currencyCode = "USD",
            phoneCountryCode = "+1",
            phoneNationalDigits = 10,
        )
    }
}
```

`SRC/core/common/format/CurrencyFormatter.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.format

import com.noshitechinc.restaurant.core.common.market.MarketConfig
import java.math.BigDecimal
import java.text.NumberFormat
import java.util.Currency

class CurrencyFormatter(market: MarketConfig = MarketConfig.UnitedStates) {
    private val currencyFormat: NumberFormat = NumberFormat.getCurrencyInstance(market.locale).apply {
        currency = Currency.getInstance(market.currencyCode)
    }
    private val amountFormat: NumberFormat = NumberFormat.getNumberInstance(market.locale).apply {
        minimumFractionDigits = FRACTION_DIGITS
        maximumFractionDigits = FRACTION_DIGITS
    }

    fun format(cents: Long): String = synchronized(currencyFormat) { currencyFormat.format(toDecimal(cents)) }

    fun formatAmount(cents: Long): String = synchronized(amountFormat) { amountFormat.format(toDecimal(cents)) }

    private fun toDecimal(cents: Long): BigDecimal = BigDecimal.valueOf(cents, FRACTION_DIGITS)

    companion object {
        const val MAX_DIGITS = 11
        private const val FRACTION_DIGITS = 2

        fun centsFromDigits(input: String): Long =
            input.filter(Char::isDigit).trimStart('0').take(MAX_DIGITS).ifEmpty { "0" }.toLong()
    }
}
```

`SRC/core/common/format/UsPhoneFormatter.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.format

object UsPhoneFormatter {
    const val NATIONAL_DIGITS = 10
    private const val AREA_END = 3
    private const val EXCHANGE_END = 6

    fun digitsOnly(input: String): String = input.filter(Char::isDigit).take(NATIONAL_DIGITS)

    fun format(digits: String): String {
        val d = digitsOnly(digits)
        return when {
            d.isEmpty() -> ""
            d.length <= AREA_END -> "($d"
            d.length <= EXCHANGE_END -> "(${d.take(AREA_END)}) ${d.drop(AREA_END)}"
            else -> "(${d.take(AREA_END)}) ${d.substring(AREA_END, EXCHANGE_END)}-${d.drop(EXCHANGE_END)}"
        }
    }

    fun originalToTransformed(offset: Int, digitCount: Int): Int {
        if (digitCount == 0) return 0
        val o = offset.coerceIn(0, digitCount)
        val transformed = when {
            o <= AREA_END -> o + 1
            o <= EXCHANGE_END -> o + 3
            else -> o + 4
        }
        return transformed.coerceAtMost(format("0".repeat(digitCount)).length)
    }

    fun transformedToOriginal(offset: Int, digitCount: Int): Int {
        val original = when {
            offset <= 1 -> 0
            offset <= 4 -> offset - 1
            offset <= 6 -> AREA_END
            offset <= 9 -> offset - 3
            offset == 10 -> EXCHANGE_END
            else -> offset - 4
        }
        return original.coerceIn(0, digitCount)
    }
}
```

`SRC/core/common/model/PostalAddress.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.model

data class PostalAddress(
    val street: String = "",
    val unit: String = "",
    val city: String = "",
    val state: String = "",
    val zip: String = "",
)
```

`SRC/core/common/validation/UsPhoneValidator.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.validation

import com.noshitechinc.restaurant.core.common.format.UsPhoneFormatter

object UsPhoneValidator {
    private const val EXCHANGE_START = 3

    fun isValid(digits: String): Boolean =
        digits.length == UsPhoneFormatter.NATIONAL_DIGITS &&
            digits.all(Char::isDigit) &&
            digits[0] in '2'..'9' &&
            digits[EXCHANGE_START] in '2'..'9'
}
```

`SRC/core/common/validation/UsAddressValidator.kt`
```kotlin
package com.noshitechinc.restaurant.core.common.validation

import com.noshitechinc.restaurant.core.common.model.PostalAddress

enum class AddressField { Street, City, State, Zip }

object UsAddressValidator {
    private val zipRegex = Regex("^\\d{5}(-\\d{4})?$")
    private val stateRegex = Regex("^[A-Za-z]{2}$")

    fun invalidFields(address: PostalAddress): Set<AddressField> = buildSet {
        if (address.street.isBlank()) add(AddressField.Street)
        if (address.city.isBlank()) add(AddressField.City)
        if (!stateRegex.matches(address.state.trim())) add(AddressField.State)
        if (!zipRegex.matches(address.zip.trim())) add(AddressField.Zip)
    }
}
```

`SRC/di/CoroutinesModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import com.noshitechinc.restaurant.core.common.coroutines.ApplicationScope
import com.noshitechinc.restaurant.core.common.coroutines.DefaultDispatcher
import com.noshitechinc.restaurant.core.common.coroutines.IoDispatcher
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

@Module
@InstallIn(SingletonComponent::class)
object CoroutinesModule {
    @Provides
    @IoDispatcher
    fun ioDispatcher(): CoroutineDispatcher = Dispatchers.IO

    @Provides
    @DefaultDispatcher
    fun defaultDispatcher(): CoroutineDispatcher = Dispatchers.Default

    @Provides
    @Singleton
    @ApplicationScope
    fun applicationScope(@DefaultDispatcher dispatcher: CoroutineDispatcher): CoroutineScope =
        CoroutineScope(SupervisorJob() + dispatcher)
}
```

`SRC/di/AppModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import com.noshitechinc.restaurant.BuildConfig
import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.core.common.format.CurrencyFormatter
import com.noshitechinc.restaurant.core.common.market.MarketConfig
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    @Provides
    @Singleton
    fun appInfo(): AppInfo = AppInfo(
        environment = AppEnvironment.from(BuildConfig.ENVIRONMENT),
        versionName = BuildConfig.VERSION_NAME,
        versionCode = BuildConfig.VERSION_CODE,
    )

    @Provides
    fun marketConfig(): MarketConfig = MarketConfig.UnitedStates

    @Provides
    @Singleton
    fun currencyFormatter(market: MarketConfig): CurrencyFormatter = CurrencyFormatter(market)
}
```

- [ ] **Step 4: Run tests — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest --console=plain`
Expected: `BUILD SUCCESSFUL`; the four test classes pass.

- [ ] **Step 5: Checkpoint** — list files.

---

### Task 3: `core/logging` — Timber trees, CrashReporter, Crashlytics wiring, app startup

**Files:**
- Create: `SRC/core/logging/CrashReporter.kt`, `SRC/core/logging/CrashlyticsCrashReporter.kt`, `SRC/core/logging/CrashReportingTree.kt`, `SRC/core/logging/AppLogging.kt`
- Create: `SRC/di/LoggingModule.kt`
- Create: `SRC/app/AppStartup.kt`
- Modify: `SRC/app/RestaurantApplication.kt`
- Test: `TEST/core/logging/CrashReportingTreeTest.kt`, `TEST/fakes/FakeCrashReporter.kt`

**Interfaces:**
- Consumes: `AppInfo`, `AppEnvironment`.
- Produces: `interface CrashReporter { setUserId(id: String?); setKey(key: String, value: String); log(message: String); recordException(throwable: Throwable) }`, `object NoOpCrashReporter`, `class CrashlyticsCrashReporter(crashlytics)`, `class CrashReportingTree(reporter)`, `object AppLogging { install(appInfo: AppInfo, reporter: CrashReporter) }`, `class AppStartup @Inject constructor(...) { fun run() }` (Task 5 adds token hydration to it).

- [ ] **Step 1: Write failing test + fake**

`TEST/fakes/FakeCrashReporter.kt`
```kotlin
package com.noshitechinc.restaurant.fakes

import com.noshitechinc.restaurant.core.logging.CrashReporter

class FakeCrashReporter : CrashReporter {
    val logs = mutableListOf<String>()
    val exceptions = mutableListOf<Throwable>()
    val keys = mutableMapOf<String, String>()
    var userId: String? = null

    override fun setUserId(id: String?) {
        userId = id
    }

    override fun setKey(key: String, value: String) {
        keys[key] = value
    }

    override fun log(message: String) {
        logs += message
    }

    override fun recordException(throwable: Throwable) {
        exceptions += throwable
    }
}
```

`TEST/core/logging/CrashReportingTreeTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.logging

import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.fakes.FakeCrashReporter
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import timber.log.Timber

class CrashReportingTreeTest {
    private val reporter = FakeCrashReporter()

    @AfterTest
    fun tearDown() = Timber.uprootAll()

    @Test
    fun `drops debug logs and forwards info as breadcrumbs`() {
        Timber.plant(CrashReportingTree(reporter))
        Timber.d("debug detail")
        Timber.i("order screen opened")
        assertEquals(1, reporter.logs.size)
        assertTrue(reporter.logs.single().startsWith("I/"))
    }

    @Test
    fun `records exceptions logged at warn or above`() {
        Timber.plant(CrashReportingTree(reporter))
        val error = IllegalStateException("boom")
        Timber.w(error, "warned")
        Timber.i(RuntimeException("ignored"), "info with throwable")
        assertEquals(listOf<Throwable>(error), reporter.exceptions)
    }

    @Test
    fun `install sets environment keys and plants crash tree outside dev`() {
        AppLogging.install(AppInfo(AppEnvironment.Staging, "1.2.3", 7), reporter)
        Timber.e(IllegalArgumentException("bad"), "failed")
        assertEquals("staging", reporter.keys["environment"])
        assertEquals("1.2.3 (7)", reporter.keys["version"])
        assertEquals("tablet", reporter.keys["device_class"])
        assertEquals(1, reporter.exceptions.size)
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (`./gradlew testDevDebugUnitTest`, unresolved `CrashReportingTree`).

- [ ] **Step 3: Implement**

`SRC/core/logging/CrashReporter.kt`
```kotlin
package com.noshitechinc.restaurant.core.logging

interface CrashReporter {
    fun setUserId(id: String?)
    fun setKey(key: String, value: String)
    fun log(message: String)
    fun recordException(throwable: Throwable)
}

object NoOpCrashReporter : CrashReporter {
    override fun setUserId(id: String?) = Unit
    override fun setKey(key: String, value: String) = Unit
    override fun log(message: String) = Unit
    override fun recordException(throwable: Throwable) = Unit
}
```

`SRC/core/logging/CrashlyticsCrashReporter.kt`
```kotlin
package com.noshitechinc.restaurant.core.logging

import com.google.firebase.crashlytics.FirebaseCrashlytics

class CrashlyticsCrashReporter(private val crashlytics: FirebaseCrashlytics) : CrashReporter {
    override fun setUserId(id: String?) = crashlytics.setUserId(id.orEmpty())
    override fun setKey(key: String, value: String) = crashlytics.setCustomKey(key, value)
    override fun log(message: String) = crashlytics.log(message)
    override fun recordException(throwable: Throwable) = crashlytics.recordException(throwable)
}
```

`SRC/core/logging/CrashReportingTree.kt`
```kotlin
package com.noshitechinc.restaurant.core.logging

import android.util.Log
import timber.log.Timber

class CrashReportingTree(private val reporter: CrashReporter) : Timber.Tree() {
    override fun isLoggable(tag: String?, priority: Int): Boolean = priority >= Log.INFO

    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        reporter.log("${label(priority)}/${tag ?: DEFAULT_TAG}: $message")
        if (t != null && priority >= Log.WARN) reporter.recordException(t)
    }

    private fun label(priority: Int): String = when (priority) {
        Log.INFO -> "I"
        Log.WARN -> "W"
        Log.ERROR -> "E"
        Log.ASSERT -> "A"
        else -> "D"
    }

    private companion object {
        const val DEFAULT_TAG = "App"
    }
}
```

`SRC/core/logging/AppLogging.kt`
```kotlin
package com.noshitechinc.restaurant.core.logging

import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import timber.log.Timber

object AppLogging {
    fun install(appInfo: AppInfo, reporter: CrashReporter) {
        if (appInfo.environment == AppEnvironment.Dev) {
            Timber.plant(Timber.DebugTree())
        } else {
            Timber.plant(CrashReportingTree(reporter))
        }
        reporter.setKey("environment", appInfo.environment.name.lowercase())
        reporter.setKey("version", "${appInfo.versionName} (${appInfo.versionCode})")
        reporter.setKey("device_class", "tablet")
    }
}
```

`SRC/di/LoggingModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import android.content.Context
import com.google.firebase.FirebaseApp
import com.google.firebase.crashlytics.FirebaseCrashlytics
import com.noshitechinc.restaurant.BuildConfig
import com.noshitechinc.restaurant.core.logging.CrashReporter
import com.noshitechinc.restaurant.core.logging.CrashlyticsCrashReporter
import com.noshitechinc.restaurant.core.logging.NoOpCrashReporter
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object LoggingModule {
    @Provides
    @Singleton
    fun crashReporter(@ApplicationContext context: Context): CrashReporter =
        if (BuildConfig.CRASH_REPORTING_ENABLED && FirebaseApp.getApps(context).isNotEmpty()) {
            CrashlyticsCrashReporter(FirebaseCrashlytics.getInstance())
        } else {
            NoOpCrashReporter
        }
}
```

`SRC/app/AppStartup.kt`
```kotlin
package com.noshitechinc.restaurant.app

import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.core.logging.AppLogging
import com.noshitechinc.restaurant.core.logging.CrashReporter
import javax.inject.Inject

class AppStartup @Inject constructor(
    private val appInfo: AppInfo,
    private val crashReporter: CrashReporter,
) {
    fun run() {
        AppLogging.install(appInfo, crashReporter)
    }
}
```

`SRC/app/RestaurantApplication.kt`
```kotlin
package com.noshitechinc.restaurant.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp
import javax.inject.Inject

@HiltAndroidApp
class RestaurantApplication : Application() {
    @Inject
    lateinit var appStartup: AppStartup

    override fun onCreate() {
        super.onCreate()
        appStartup.run()
    }
}
```

Also create `SRC/core/adaptive/OrientationPolicy.kt` now (tests arrive in Task 6):
```kotlin
package com.noshitechinc.restaurant.core.adaptive

import android.content.pm.ActivityInfo

object OrientationPolicy {
    const val TABLET_MIN_SMALLEST_WIDTH_DP = 600

    fun isTablet(smallestScreenWidthDp: Int): Boolean = smallestScreenWidthDp >= TABLET_MIN_SMALLEST_WIDTH_DP

    @Suppress("UNUSED_PARAMETER")
    fun requestedOrientation(smallestScreenWidthDp: Int): Int = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
}
```

- [ ] **Step 4: Run tests + dev build — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest assembleDevDebug --console=plain`
Expected: `BUILD SUCCESSFUL`.

- [ ] **Step 5: Checkpoint** — list files.

---

### Task 4: `core/network` errors — body parser, sanitizer, mapper, `SafeApiCall`

**Files:**
- Create: `SRC/core/network/NetworkConstants.kt`, `SRC/core/network/error/ErrorBodyParser.kt`, `SRC/core/network/error/MessageSanitizer.kt`, `SRC/core/network/error/ErrorMapper.kt`, `SRC/core/network/SafeApiCall.kt`
- Test: `TEST/core/network/error/MessageSanitizerTest.kt`, `TEST/core/network/error/ErrorMapperTest.kt`, `TEST/core/network/SafeApiCallTest.kt`

**Interfaces (Produces):**
- `const val NO_AUTH_HEADER = "X-No-Auth"`, `const val AUTHORIZATION_HEADER = "Authorization"`, `const val BEARER_PREFIX = "Bearer "`
- `data class ParsedError(message: String?, code: String?, fieldErrors: Map<String, List<String>>)`, `fun interface ErrorBodyParser { fun parse(body: String): ParsedError? }`, `class JsonErrorBodyParser @Inject constructor(json: Json)`
- `object MessageSanitizer { MAX_LENGTH = 280; fun sanitize(raw: String?): String? }`
- `class ErrorMapper @Inject constructor(parser: ErrorBodyParser) { fun map(throwable: Throwable): AppError; fun fromHttp(code: Int, body: String?): AppError }`
- `class SafeApiCall @Inject constructor(errorMapper: ErrorMapper) { suspend operator fun <T> invoke(block: suspend () -> T): ApiResult<T> }` — repositories inject it as `safeApiCall` and call `safeApiCall { api.foo() }`.

- [ ] **Step 1: Write failing tests**

`TEST/core/network/error/MessageSanitizerTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.error

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class MessageSanitizerTest {
    @Test
    fun `keeps short human messages`() {
        assertEquals("Table 4 already has an open order.", MessageSanitizer.sanitize("  Table 4 already has an open order. "))
    }

    @Test
    fun `rejects blank long and technical messages`() {
        assertNull(MessageSanitizer.sanitize(null))
        assertNull(MessageSanitizer.sanitize("   "))
        assertNull(MessageSanitizer.sanitize("x".repeat(MessageSanitizer.MAX_LENGTH + 1)))
        assertNull(MessageSanitizer.sanitize("java.lang.NullPointerException: order"))
        assertNull(MessageSanitizer.sanitize("<html><body>502</body></html>"))
        assertNull(MessageSanitizer.sanitize("SQLSTATE[23000]: Integrity constraint"))
        assertNull(MessageSanitizer.sanitize("failed at com.example.Foo.bar(Foo.kt:12)"))
    }
}
```

`TEST/core/network/error/ErrorMapperTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.error

import com.noshitechinc.restaurant.core.common.AppError
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlinx.serialization.json.Json
import okhttp3.ResponseBody.Companion.toResponseBody
import retrofit2.HttpException
import retrofit2.Response

class ErrorMapperTest {
    private val mapper = ErrorMapper(JsonErrorBodyParser(Json { ignoreUnknownKeys = true }))

    private fun http(code: Int, body: String = "") = HttpException(Response.error<Any>(code, body.toResponseBody()))

    @Test
    fun `maps connectivity exceptions`() {
        assertEquals(AppError.Timeout, mapper.map(SocketTimeoutException()))
        assertEquals(AppError.NoInternet, mapper.map(UnknownHostException()))
        assertEquals(AppError.NoInternet, mapper.map(IOException("reset")))
    }

    @Test
    fun `maps http status codes`() {
        assertEquals(AppError.SessionExpired, mapper.map(http(401)))
        assertEquals(AppError.Forbidden, mapper.map(http(403)))
        assertEquals(AppError.NotFound, mapper.map(http(404)))
        assertEquals(AppError.ServiceUnavailable, mapper.map(http(502)))
        assertEquals(AppError.ServiceUnavailable, mapper.map(http(503)))
        assertEquals(AppError.ServiceUnavailable, mapper.map(http(504)))
        assertEquals(AppError.Server(500, null), mapper.map(http(500)))
    }

    @Test
    fun `validation errors carry sanitized message and field errors`() {
        val body = """{"message":"Quantity must be at least 1","code":"VALIDATION","errors":{"quantity":["Must be at least 1"]}}"""
        val error = mapper.map(http(422, body))
        assertEquals(AppError.Validation("Quantity must be at least 1", mapOf("quantity" to listOf("Must be at least 1"))), error)
    }

    @Test
    fun `technical server messages are dropped`() {
        val error = mapper.map(http(500, """{"message":"java.lang.IllegalStateException: boom"}"""))
        assertEquals(AppError.Server(500, null), error)
    }

    @Test
    fun `unparseable bodies do not crash`() {
        assertEquals(AppError.Validation(null, emptyMap()), mapper.map(http(400, "not json")))
    }

    @Test
    fun `unexpected exceptions map to unknown`() {
        assertIs<AppError.Unknown>(mapper.map(IllegalStateException("bug")))
    }
}
```

`TEST/core/network/SafeApiCallTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import com.noshitechinc.restaurant.core.common.ApiResult
import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.core.network.error.ErrorMapper
import com.noshitechinc.restaurant.core.network.error.JsonErrorBodyParser
import java.net.UnknownHostException
import kotlin.coroutines.cancellation.CancellationException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlinx.coroutines.test.runTest
import kotlinx.serialization.json.Json

class SafeApiCallTest {
    private val safeApiCall = SafeApiCall(ErrorMapper(JsonErrorBodyParser(Json)))

    @Test
    fun `wraps success`() = runTest {
        assertEquals(ApiResult.Success(42), safeApiCall.invoke { 42 })
    }

    @Test
    fun `maps failures`() = runTest {
        val result: ApiResult<Int> = safeApiCall.invoke { throw UnknownHostException() }
        assertEquals(ApiResult.Failure(AppError.NoInternet), result)
    }

    @Test
    fun `rethrows cancellation`() = runTest {
        assertFailsWith<CancellationException> {
            safeApiCall.invoke<Int> { throw CancellationException("cancelled") }
        }
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (`./gradlew testDevDebugUnitTest`, unresolved references).

- [ ] **Step 3: Implement**

`SRC/core/network/NetworkConstants.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

const val NO_AUTH_HEADER = "X-No-Auth"
const val AUTHORIZATION_HEADER = "Authorization"
const val BEARER_PREFIX = "Bearer "
```

`SRC/core/network/error/ErrorBodyParser.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.error

import javax.inject.Inject
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json

data class ParsedError(
    val message: String?,
    val code: String?,
    val fieldErrors: Map<String, List<String>>,
)

fun interface ErrorBodyParser {
    fun parse(body: String): ParsedError?
}

class JsonErrorBodyParser @Inject constructor(private val json: Json) : ErrorBodyParser {
    override fun parse(body: String): ParsedError? = try {
        json.decodeFromString<ErrorBodyDto>(body).let { ParsedError(it.message, it.code, it.errors.orEmpty()) }
    } catch (e: IllegalArgumentException) {
        null
    }
}

@Serializable
internal data class ErrorBodyDto(
    val message: String? = null,
    val code: String? = null,
    val errors: Map<String, List<String>>? = null,
)
```

`SRC/core/network/error/MessageSanitizer.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.error

object MessageSanitizer {
    const val MAX_LENGTH = 280
    private val technical = Regex(
        "(?i)(exception|stack ?trace|sqlstate|syntax error|null ?pointer|<[a-z!/]|\\bat [\\w.$]+\\()",
    )

    fun sanitize(raw: String?): String? {
        val text = raw?.trim().orEmpty()
        return text.takeIf { it.isNotEmpty() && it.length <= MAX_LENGTH && !technical.containsMatchIn(it) }
    }
}
```

`SRC/core/network/error/ErrorMapper.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.error

import com.noshitechinc.restaurant.core.common.AppError
import java.io.IOException
import java.net.SocketTimeoutException
import javax.inject.Inject
import retrofit2.HttpException

class ErrorMapper @Inject constructor(private val parser: ErrorBodyParser) {
    fun map(throwable: Throwable): AppError = when (throwable) {
        is HttpException -> fromHttp(throwable.code(), throwable.response()?.errorBody()?.string())
        is SocketTimeoutException -> AppError.Timeout
        is IOException -> AppError.NoInternet
        else -> AppError.Unknown(throwable)
    }

    fun fromHttp(code: Int, body: String?): AppError {
        val parsed = body?.takeIf { it.isNotBlank() }?.let(parser::parse)
        val message = MessageSanitizer.sanitize(parsed?.message)
        return when (code) {
            HTTP_UNAUTHORIZED -> AppError.SessionExpired
            HTTP_FORBIDDEN -> AppError.Forbidden
            HTTP_NOT_FOUND -> AppError.NotFound
            in SERVICE_UNAVAILABLE -> AppError.ServiceUnavailable
            in CLIENT_ERRORS -> AppError.Validation(message, parsed?.fieldErrors.orEmpty())
            else -> AppError.Server(code, message)
        }
    }

    private companion object {
        const val HTTP_UNAUTHORIZED = 401
        const val HTTP_FORBIDDEN = 403
        const val HTTP_NOT_FOUND = 404
        val SERVICE_UNAVAILABLE = setOf(502, 503, 504)
        val CLIENT_ERRORS = 400..499
    }
}
```

`SRC/core/network/SafeApiCall.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import com.noshitechinc.restaurant.core.common.ApiResult
import com.noshitechinc.restaurant.core.network.error.ErrorMapper
import javax.inject.Inject
import kotlin.coroutines.cancellation.CancellationException
import timber.log.Timber

class SafeApiCall @Inject constructor(private val errorMapper: ErrorMapper) {
    @Suppress("TooGenericExceptionCaught")
    suspend operator fun <T> invoke(block: suspend () -> T): ApiResult<T> = try {
        ApiResult.Success(block())
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Timber.w(e, "API call failed")
        ApiResult.Failure(errorMapper.map(e))
    }
}
```

- [ ] **Step 4: Run — expect PASS** (`./gradlew testDevDebugUnitTest`).

- [ ] **Step 5: Checkpoint** — list files.

---

### Task 5: Auth, token storage, interceptors, authenticator, Retrofit client

**Files:**
- Create: `SRC/core/auth/TokenPair.kt`, `TokenStore.kt`, `TokenCipher.kt`, `KeystoreTokenCipher.kt`, `KeystoreTokenStore.kt`, `AuthProvider.kt`, `SessionManager.kt`
- Create: `SRC/core/network/interceptor/HeaderInterceptor.kt`, `AuthInterceptor.kt`, `SRC/core/network/TokenAuthenticator.kt`, `SRC/core/network/NetworkQualifiers.kt`
- Create: `SRC/data/remote/api/AuthApi.kt`, `SRC/data/remote/dto/AuthDtos.kt`, `SRC/data/mapper/AuthMappers.kt`, `SRC/data/auth/RefreshTokenAuthProvider.kt`
- Create: `SRC/di/NetworkModule.kt`, `SRC/di/DataStoreModule.kt`, `SRC/di/BindingsModule.kt`
- Modify: `SRC/app/AppStartup.kt` (hydrate tokens)
- Test: `TEST/fakes/FakeTokenStore.kt`, `TEST/fakes/FakeAuthProvider.kt`, `TEST/fakes/FakeTokenCipher.kt`, `TEST/core/network/TokenAuthenticatorTest.kt`, `TEST/core/network/interceptor/InterceptorsTest.kt`, `TEST/core/auth/KeystoreTokenStoreTest.kt`

**Interfaces (Produces):**
- `data class TokenPair(accessToken: String, refreshToken: String?)`
- `interface TokenStore { fun currentTokens(): TokenPair?; suspend fun hydrate(); suspend fun save(tokens: TokenPair); suspend fun clear() }` (`currentTokens()` may block on first call; call only off the main thread)
- `interface TokenCipher { fun encrypt(plainText: String): String; fun decrypt(cipherText: String): String? }`
- `fun interface AuthProvider { suspend fun refresh(refreshToken: String): TokenPair? }`
- `class SessionManager @Inject constructor(tokenStore) { val sessionEnded: SharedFlow<Unit>; suspend fun startSession(tokens: TokenPair); suspend fun endSession() }`
- `fun Request.withBearer(token: String): Request`
- Qualifiers `@BaseClient`, `@AuthenticatedClient` for `OkHttpClient`; `Retrofit` (authenticated) and `AuthApi` provided as singletons.

- [ ] **Step 1: Fakes**

`TEST/fakes/FakeTokenStore.kt`
```kotlin
package com.noshitechinc.restaurant.fakes

import com.noshitechinc.restaurant.core.auth.TokenPair
import com.noshitechinc.restaurant.core.auth.TokenStore

class FakeTokenStore(initial: TokenPair? = null) : TokenStore {
    @Volatile
    private var tokens: TokenPair? = initial

    override fun currentTokens(): TokenPair? = tokens

    override suspend fun hydrate() = Unit

    override suspend fun save(tokens: TokenPair) {
        this.tokens = tokens
    }

    override suspend fun clear() {
        tokens = null
    }
}
```

`TEST/fakes/FakeAuthProvider.kt`
```kotlin
package com.noshitechinc.restaurant.fakes

import com.noshitechinc.restaurant.core.auth.AuthProvider
import com.noshitechinc.restaurant.core.auth.TokenPair
import java.util.concurrent.atomic.AtomicInteger
import kotlinx.coroutines.delay

class FakeAuthProvider(
    private val result: TokenPair?,
    private val delayMillis: Long = 0,
) : AuthProvider {
    val calls = AtomicInteger(0)

    override suspend fun refresh(refreshToken: String): TokenPair? {
        calls.incrementAndGet()
        if (delayMillis > 0) delay(delayMillis)
        return result
    }
}
```

`TEST/fakes/FakeTokenCipher.kt`
```kotlin
package com.noshitechinc.restaurant.fakes

import com.noshitechinc.restaurant.core.auth.TokenCipher

class FakeTokenCipher : TokenCipher {
    override fun encrypt(plainText: String): String = "enc:" + plainText.reversed()

    override fun decrypt(cipherText: String): String? =
        cipherText.takeIf { it.startsWith("enc:") }?.removePrefix("enc:")?.reversed()
}
```

- [ ] **Step 2: Write failing tests**

`TEST/core/network/TokenAuthenticatorTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import com.noshitechinc.restaurant.core.auth.SessionManager
import com.noshitechinc.restaurant.core.auth.TokenPair
import com.noshitechinc.restaurant.core.network.interceptor.AuthInterceptor
import com.noshitechinc.restaurant.fakes.FakeAuthProvider
import com.noshitechinc.restaurant.fakes.FakeTokenStore
import java.util.concurrent.Callable
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.mockwebserver.Dispatcher
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import okhttp3.mockwebserver.RecordedRequest

class TokenAuthenticatorTest {
    private val server = MockWebServer()

    @AfterTest
    fun tearDown() = server.shutdown()

    private fun serveOkOnlyFor(token: String) {
        server.dispatcher = object : Dispatcher() {
            override fun dispatch(request: RecordedRequest): MockResponse =
                if (request.getHeader(AUTHORIZATION_HEADER) == "$BEARER_PREFIX$token") {
                    MockResponse().setResponseCode(200).setBody("ok")
                } else {
                    MockResponse().setResponseCode(401)
                }
        }
        server.start()
    }

    private fun client(store: FakeTokenStore, provider: FakeAuthProvider) = OkHttpClient.Builder()
        .addInterceptor(AuthInterceptor(store))
        .authenticator(TokenAuthenticator(store, provider, SessionManager(store)))
        .build()

    private fun OkHttpClient.get(): Int =
        newCall(Request.Builder().url(server.url("/orders")).build()).execute().use { it.code }

    @Test
    fun `parallel 401s trigger a single refresh`() {
        serveOkOnlyFor("new")
        val store = FakeTokenStore(TokenPair("old", "refresh"))
        val provider = FakeAuthProvider(TokenPair("new", "refresh-2"), delayMillis = 200)
        val client = client(store, provider)
        val pool = Executors.newFixedThreadPool(3)
        val codes = List(3) { pool.submit(Callable { client.get() }) }.map { it.get(10, TimeUnit.SECONDS) }
        pool.shutdown()
        assertEquals(listOf(200, 200, 200), codes)
        assertEquals(1, provider.calls.get())
        assertEquals("new", store.currentTokens()?.accessToken)
    }

    @Test
    fun `failed refresh ends the session`() {
        serveOkOnlyFor("never")
        val store = FakeTokenStore(TokenPair("old", "refresh"))
        val provider = FakeAuthProvider(result = null)
        assertEquals(401, client(store, provider).get())
        assertNull(store.currentTokens())
    }

    @Test
    fun `retries at most once per request`() {
        serveOkOnlyFor("never")
        val store = FakeTokenStore(TokenPair("old", "refresh"))
        val provider = FakeAuthProvider(TokenPair("new", "refresh-2"))
        assertEquals(401, client(store, provider).get())
        assertEquals(2, server.requestCount)
    }

    @Test
    fun `requests without a token are not retried`() {
        serveOkOnlyFor("never")
        val store = FakeTokenStore(initial = null)
        val provider = FakeAuthProvider(TokenPair("new", null))
        assertEquals(401, client(store, provider).get())
        assertEquals(0, provider.calls.get())
        assertEquals(1, server.requestCount)
    }
}
```

`TEST/core/network/interceptor/InterceptorsTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.interceptor

import com.noshitechinc.restaurant.core.auth.TokenPair
import com.noshitechinc.restaurant.core.common.AppEnvironment
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.core.network.AUTHORIZATION_HEADER
import com.noshitechinc.restaurant.core.network.NO_AUTH_HEADER
import com.noshitechinc.restaurant.fakes.FakeTokenStore
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer

class InterceptorsTest {
    private val server = MockWebServer().apply { start() }

    @AfterTest
    fun tearDown() = server.shutdown()

    private fun client(store: FakeTokenStore) = OkHttpClient.Builder()
        .addInterceptor(HeaderInterceptor(AppInfo(AppEnvironment.Dev, "0.1.0", 1)))
        .addInterceptor(AuthInterceptor(store))
        .build()

    @Test
    fun `adds common headers and bearer token`() {
        server.enqueue(MockResponse())
        client(FakeTokenStore(TokenPair("abc", null))).newCall(Request.Builder().url(server.url("/")).build()).execute().close()
        val recorded = server.takeRequest()
        assertEquals("Bearer abc", recorded.getHeader(AUTHORIZATION_HEADER))
        assertEquals("application/json", recorded.getHeader("Accept"))
        assertEquals("en", recorded.getHeader("Accept-Language"))
        assertEquals("0.1.0", recorded.getHeader("X-App-Version"))
        assertEquals("android", recorded.getHeader("X-Platform"))
    }

    @Test
    fun `no-auth requests skip the token and strip the marker header`() {
        server.enqueue(MockResponse())
        val request = Request.Builder().url(server.url("/")).header(NO_AUTH_HEADER, "true").build()
        client(FakeTokenStore(TokenPair("abc", null))).newCall(request).execute().close()
        val recorded = server.takeRequest()
        assertNull(recorded.getHeader(AUTHORIZATION_HEADER))
        assertNull(recorded.getHeader(NO_AUTH_HEADER))
    }
}
```

`TEST/core/auth/KeystoreTokenStoreTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import com.noshitechinc.restaurant.fakes.FakeTokenCipher
import java.io.File
import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest

class KeystoreTokenStoreTest {
    private val dir: File = Files.createTempDirectory("tokens").toFile()
    private val dataStore = PreferenceDataStoreFactory.create(produceFile = { File(dir, "session.preferences_pb") })
    private val cipher = FakeTokenCipher()

    @Test
    fun `save encrypts values and caches tokens`() = runTest {
        val store = KeystoreTokenStore(dataStore, cipher)
        store.save(TokenPair("access-1", "refresh-1"))
        val raw = dataStore.data.first()[stringPreferencesKey("access_token")].orEmpty()
        assertFalse(raw.contains("access-1"))
        assertEquals(TokenPair("access-1", "refresh-1"), store.currentTokens())
    }

    @Test
    fun `hydrate restores tokens written earlier`() = runTest {
        dataStore.edit {
            it[stringPreferencesKey("access_token")] = cipher.encrypt("access-2")
            it[stringPreferencesKey("refresh_token")] = cipher.encrypt("refresh-2")
        }
        val store = KeystoreTokenStore(dataStore, cipher)
        store.hydrate()
        assertEquals(TokenPair("access-2", "refresh-2"), store.currentTokens())
    }

    @Test
    fun `clear removes tokens`() = runTest {
        val store = KeystoreTokenStore(dataStore, cipher)
        store.save(TokenPair("access-3", null))
        store.clear()
        assertNull(store.currentTokens())
        assertNull(dataStore.data.first()[stringPreferencesKey("access_token")])
    }
}
```

- [ ] **Step 3: Run — expect FAIL** (`./gradlew testDevDebugUnitTest`).

- [ ] **Step 4: Implement auth**

`SRC/core/auth/TokenPair.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

data class TokenPair(val accessToken: String, val refreshToken: String?)
```

`SRC/core/auth/TokenStore.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

interface TokenStore {
    fun currentTokens(): TokenPair?
    suspend fun hydrate()
    suspend fun save(tokens: TokenPair)
    suspend fun clear()
}
```

`SRC/core/auth/TokenCipher.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

interface TokenCipher {
    fun encrypt(plainText: String): String
    fun decrypt(cipherText: String): String?
}
```

`SRC/core/auth/KeystoreTokenCipher.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.GeneralSecurityException
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class KeystoreTokenCipher @Inject constructor() : TokenCipher {
    private val keyStore: KeyStore = KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }

    override fun encrypt(plainText: String): String {
        val cipher = Cipher.getInstance(TRANSFORMATION).apply { init(Cipher.ENCRYPT_MODE, secretKey()) }
        val encrypted = cipher.doFinal(plainText.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(cipher.iv + encrypted, Base64.NO_WRAP)
    }

    override fun decrypt(cipherText: String): String? = try {
        val bytes = Base64.decode(cipherText, Base64.NO_WRAP)
        val iv = bytes.copyOfRange(0, IV_SIZE_BYTES)
        val payload = bytes.copyOfRange(IV_SIZE_BYTES, bytes.size)
        val cipher = Cipher.getInstance(TRANSFORMATION).apply {
            init(Cipher.DECRYPT_MODE, secretKey(), GCMParameterSpec(TAG_SIZE_BITS, iv))
        }
        String(cipher.doFinal(payload), Charsets.UTF_8)
    } catch (e: GeneralSecurityException) {
        null
    } catch (e: IllegalArgumentException) {
        null
    }

    private fun secretKey(): SecretKey =
        (keyStore.getEntry(KEY_ALIAS, null) as? KeyStore.SecretKeyEntry)?.secretKey ?: generateKey()

    private fun generateKey(): SecretKey = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE).apply {
        init(
            KeyGenParameterSpec.Builder(KEY_ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(KEY_SIZE_BITS)
                .build(),
        )
    }.generateKey()

    private companion object {
        const val ANDROID_KEYSTORE = "AndroidKeyStore"
        const val KEY_ALIAS = "restaurant_session_key"
        const val TRANSFORMATION = "AES/GCM/NoPadding"
        const val IV_SIZE_BYTES = 12
        const val TAG_SIZE_BITS = 128
        const val KEY_SIZE_BITS = 256
    }
}
```

`SRC/core/auth/KeystoreTokenStore.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

@Singleton
class KeystoreTokenStore @Inject constructor(
    private val dataStore: DataStore<Preferences>,
    private val cipher: TokenCipher,
) : TokenStore {
    @Volatile
    private var cached: TokenPair? = null

    @Volatile
    private var hydrated = false
    private val mutex = Mutex()

    override fun currentTokens(): TokenPair? {
        if (!hydrated) runBlocking { hydrate() }
        return cached
    }

    override suspend fun hydrate() {
        mutex.withLock {
            if (hydrated) return
            val prefs = dataStore.data.first()
            val access = prefs[ACCESS_KEY]?.let(cipher::decrypt)
            cached = access?.let { TokenPair(it, prefs[REFRESH_KEY]?.let(cipher::decrypt)) }
            hydrated = true
        }
    }

    override suspend fun save(tokens: TokenPair) {
        mutex.withLock {
            dataStore.edit { prefs ->
                prefs[ACCESS_KEY] = cipher.encrypt(tokens.accessToken)
                val refresh = tokens.refreshToken
                if (refresh != null) prefs[REFRESH_KEY] = cipher.encrypt(refresh) else prefs.remove(REFRESH_KEY)
            }
            cached = tokens
            hydrated = true
        }
    }

    override suspend fun clear() {
        mutex.withLock {
            dataStore.edit { prefs ->
                prefs.remove(ACCESS_KEY)
                prefs.remove(REFRESH_KEY)
            }
            cached = null
            hydrated = true
        }
    }

    private companion object {
        val ACCESS_KEY = stringPreferencesKey("access_token")
        val REFRESH_KEY = stringPreferencesKey("refresh_token")
    }
}
```

`SRC/core/auth/AuthProvider.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

fun interface AuthProvider {
    suspend fun refresh(refreshToken: String): TokenPair?
}
```

`SRC/core/auth/SessionManager.kt`
```kotlin
package com.noshitechinc.restaurant.core.auth

import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow

@Singleton
class SessionManager @Inject constructor(private val tokenStore: TokenStore) {
    private val _sessionEnded = MutableSharedFlow<Unit>(extraBufferCapacity = 1)
    val sessionEnded: SharedFlow<Unit> = _sessionEnded.asSharedFlow()

    suspend fun startSession(tokens: TokenPair) = tokenStore.save(tokens)

    suspend fun endSession() {
        tokenStore.clear()
        _sessionEnded.emit(Unit)
    }
}
```

- [ ] **Step 5: Implement network client pieces**

`SRC/core/network/interceptor/HeaderInterceptor.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.interceptor

import com.noshitechinc.restaurant.core.common.AppInfo
import javax.inject.Inject
import okhttp3.Interceptor
import okhttp3.Response

class HeaderInterceptor @Inject constructor(private val appInfo: AppInfo) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response = chain.proceed(
        chain.request().newBuilder()
            .header("Accept", "application/json")
            .header("Accept-Language", "en")
            .header("X-App-Version", appInfo.versionName)
            .header("X-Platform", "android")
            .build(),
    )
}
```

`SRC/core/network/interceptor/AuthInterceptor.kt`
```kotlin
package com.noshitechinc.restaurant.core.network.interceptor

import com.noshitechinc.restaurant.core.auth.TokenStore
import com.noshitechinc.restaurant.core.network.AUTHORIZATION_HEADER
import com.noshitechinc.restaurant.core.network.BEARER_PREFIX
import com.noshitechinc.restaurant.core.network.NO_AUTH_HEADER
import javax.inject.Inject
import okhttp3.Interceptor
import okhttp3.Request
import okhttp3.Response

class AuthInterceptor @Inject constructor(private val tokenStore: TokenStore) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val request = chain.request()
        if (request.header(NO_AUTH_HEADER) != null) {
            return chain.proceed(request.newBuilder().removeHeader(NO_AUTH_HEADER).build())
        }
        val token = tokenStore.currentTokens()?.accessToken ?: return chain.proceed(request)
        return chain.proceed(request.withBearer(token))
    }
}

fun Request.withBearer(token: String): Request = newBuilder().header(AUTHORIZATION_HEADER, "$BEARER_PREFIX$token").build()
```

`SRC/core/network/TokenAuthenticator.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import com.noshitechinc.restaurant.core.auth.AuthProvider
import com.noshitechinc.restaurant.core.auth.SessionManager
import com.noshitechinc.restaurant.core.auth.TokenStore
import com.noshitechinc.restaurant.core.network.interceptor.withBearer
import javax.inject.Inject
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okhttp3.Authenticator
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route

class TokenAuthenticator @Inject constructor(
    private val tokenStore: TokenStore,
    private val authProvider: AuthProvider,
    private val sessionManager: SessionManager,
) : Authenticator {
    private val mutex = Mutex()

    override fun authenticate(route: Route?, response: Response): Request? {
        val failedToken = response.request.header(AUTHORIZATION_HEADER)?.removePrefix(BEARER_PREFIX) ?: return null
        if (response.priorResponse != null) return null
        return runBlocking { mutex.withLock { renew(response.request, failedToken) } }
    }

    private suspend fun renew(request: Request, failedToken: String): Request? {
        val current = tokenStore.currentTokens() ?: return null
        if (current.accessToken != failedToken) return request.withBearer(current.accessToken)
        val refreshed = current.refreshToken?.let { authProvider.refresh(it) }
        if (refreshed == null) {
            sessionManager.endSession()
            return null
        }
        tokenStore.save(refreshed)
        return request.withBearer(refreshed.accessToken)
    }
}
```

`SRC/core/network/NetworkQualifiers.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import javax.inject.Qualifier

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class BaseClient

@Qualifier
@Retention(AnnotationRetention.BINARY)
annotation class AuthenticatedClient
```

`SRC/data/remote/dto/AuthDtos.kt`
```kotlin
package com.noshitechinc.restaurant.data.remote.dto

import kotlinx.serialization.Serializable

@Serializable
data class RefreshTokenRequestDto(val refreshToken: String)

@Serializable
data class TokenResponseDto(val accessToken: String, val refreshToken: String? = null)
```

`SRC/data/remote/api/AuthApi.kt`
```kotlin
package com.noshitechinc.restaurant.data.remote.api

import com.noshitechinc.restaurant.core.network.NO_AUTH_HEADER
import com.noshitechinc.restaurant.data.remote.dto.RefreshTokenRequestDto
import com.noshitechinc.restaurant.data.remote.dto.TokenResponseDto
import retrofit2.http.Body
import retrofit2.http.Headers
import retrofit2.http.POST

interface AuthApi {
    @Headers("$NO_AUTH_HEADER: true")
    @POST("auth/refresh")
    suspend fun refresh(@Body body: RefreshTokenRequestDto): TokenResponseDto
}
```

`SRC/data/mapper/AuthMappers.kt`
```kotlin
package com.noshitechinc.restaurant.data.mapper

import com.noshitechinc.restaurant.core.auth.TokenPair
import com.noshitechinc.restaurant.data.remote.dto.TokenResponseDto

fun TokenResponseDto.toTokenPair(): TokenPair = TokenPair(accessToken = accessToken, refreshToken = refreshToken)
```

`SRC/data/auth/RefreshTokenAuthProvider.kt`
```kotlin
package com.noshitechinc.restaurant.data.auth

import com.noshitechinc.restaurant.core.auth.AuthProvider
import com.noshitechinc.restaurant.core.auth.TokenPair
import com.noshitechinc.restaurant.data.mapper.toTokenPair
import com.noshitechinc.restaurant.data.remote.api.AuthApi
import com.noshitechinc.restaurant.data.remote.dto.RefreshTokenRequestDto
import javax.inject.Inject
import kotlin.coroutines.cancellation.CancellationException
import timber.log.Timber

class RefreshTokenAuthProvider @Inject constructor(private val authApi: AuthApi) : AuthProvider {
    @Suppress("TooGenericExceptionCaught")
    override suspend fun refresh(refreshToken: String): TokenPair? = try {
        authApi.refresh(RefreshTokenRequestDto(refreshToken)).toTokenPair()
    } catch (e: CancellationException) {
        throw e
    } catch (e: Exception) {
        Timber.w(e, "Token refresh failed")
        null
    }
}
```

- [ ] **Step 6: DI modules and startup hydration**

`SRC/di/DataStoreModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.preferencesDataStore
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

private val Context.sessionDataStore: DataStore<Preferences> by preferencesDataStore(name = "secure_session")

@Module
@InstallIn(SingletonComponent::class)
object DataStoreModule {
    @Provides
    @Singleton
    fun sessionDataStore(@ApplicationContext context: Context): DataStore<Preferences> = context.sessionDataStore
}
```

`SRC/di/BindingsModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import com.noshitechinc.restaurant.core.auth.AuthProvider
import com.noshitechinc.restaurant.core.auth.KeystoreTokenCipher
import com.noshitechinc.restaurant.core.auth.KeystoreTokenStore
import com.noshitechinc.restaurant.core.auth.TokenCipher
import com.noshitechinc.restaurant.core.auth.TokenStore
import com.noshitechinc.restaurant.core.network.error.ErrorBodyParser
import com.noshitechinc.restaurant.core.network.error.JsonErrorBodyParser
import com.noshitechinc.restaurant.data.auth.RefreshTokenAuthProvider
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent

@Module
@InstallIn(SingletonComponent::class)
abstract class BindingsModule {
    @Binds
    abstract fun tokenStore(impl: KeystoreTokenStore): TokenStore

    @Binds
    abstract fun tokenCipher(impl: KeystoreTokenCipher): TokenCipher

    @Binds
    abstract fun authProvider(impl: RefreshTokenAuthProvider): AuthProvider

    @Binds
    abstract fun errorBodyParser(impl: JsonErrorBodyParser): ErrorBodyParser
}
```

`SRC/di/NetworkModule.kt`
```kotlin
package com.noshitechinc.restaurant.di

import com.noshitechinc.restaurant.BuildConfig
import com.noshitechinc.restaurant.core.network.AUTHORIZATION_HEADER
import com.noshitechinc.restaurant.core.network.AuthenticatedClient
import com.noshitechinc.restaurant.core.network.BaseClient
import com.noshitechinc.restaurant.core.network.TokenAuthenticator
import com.noshitechinc.restaurant.core.network.interceptor.AuthInterceptor
import com.noshitechinc.restaurant.core.network.interceptor.HeaderInterceptor
import com.noshitechinc.restaurant.data.remote.api.AuthApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import java.util.concurrent.TimeUnit
import javax.inject.Singleton
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory
import timber.log.Timber

@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {
    private val jsonMediaType = "application/json".toMediaType()

    @Provides
    @Singleton
    fun json(): Json = Json {
        ignoreUnknownKeys = true
        explicitNulls = false
        coerceInputValues = true
    }

    @Provides
    @Singleton
    fun loggingInterceptor(): HttpLoggingInterceptor = HttpLoggingInterceptor { Timber.tag("HTTP").d(it) }.apply {
        level = HttpLoggingInterceptor.Level.valueOf(BuildConfig.HTTP_LOG_LEVEL)
        redactHeader(AUTHORIZATION_HEADER)
        redactHeader("Cookie")
        redactHeader("Set-Cookie")
    }

    @Provides
    @Singleton
    @BaseClient
    fun baseClient(headerInterceptor: HeaderInterceptor, logging: HttpLoggingInterceptor): OkHttpClient =
        OkHttpClient.Builder()
            .connectTimeout(BuildConfig.CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(BuildConfig.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(BuildConfig.READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .addInterceptor(headerInterceptor)
            .addInterceptor(logging)
            .build()

    @Provides
    @Singleton
    @AuthenticatedClient
    fun authenticatedClient(
        @BaseClient base: OkHttpClient,
        authInterceptor: AuthInterceptor,
        authenticator: TokenAuthenticator,
    ): OkHttpClient = base.newBuilder()
        .apply { interceptors().add(1, authInterceptor) }
        .authenticator(authenticator)
        .build()

    @Provides
    @Singleton
    fun retrofit(@AuthenticatedClient client: OkHttpClient, json: Json): Retrofit = Retrofit.Builder()
        .baseUrl(BuildConfig.API_BASE_URL)
        .client(client)
        .addConverterFactory(json.asConverterFactory(jsonMediaType))
        .build()

    @Provides
    @Singleton
    fun authApi(@BaseClient client: OkHttpClient, json: Json): AuthApi = Retrofit.Builder()
        .baseUrl(BuildConfig.API_BASE_URL)
        .client(client)
        .addConverterFactory(json.asConverterFactory(jsonMediaType))
        .build()
        .create(AuthApi::class.java)
}
```

`SRC/app/AppStartup.kt` (replace)
```kotlin
package com.noshitechinc.restaurant.app

import com.noshitechinc.restaurant.core.auth.TokenStore
import com.noshitechinc.restaurant.core.common.AppInfo
import com.noshitechinc.restaurant.core.common.coroutines.ApplicationScope
import com.noshitechinc.restaurant.core.common.coroutines.IoDispatcher
import com.noshitechinc.restaurant.core.logging.AppLogging
import com.noshitechinc.restaurant.core.logging.CrashReporter
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.launch

class AppStartup @Inject constructor(
    private val appInfo: AppInfo,
    private val crashReporter: CrashReporter,
    private val tokenStore: TokenStore,
    @ApplicationScope private val applicationScope: CoroutineScope,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher,
) {
    fun run() {
        AppLogging.install(appInfo, crashReporter)
        applicationScope.launch(ioDispatcher) { tokenStore.hydrate() }
    }
}
```

- [ ] **Step 7: Run tests + build — expect PASS**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew testDevDebugUnitTest assembleDevDebug --console=plain`
Expected: `BUILD SUCCESSFUL` (Hilt graph compiles; all auth/network tests pass).

- [ ] **Step 8: Doc sync** — context repo: confirm `API-REGISTRY.md` row `api:auth:refresh` matches `AuthApi` (path `auth/refresh`, DTO fields `refreshToken`, `accessToken`); ADR-004 lists the interceptor order `HeaderInterceptor → AuthInterceptor → HttpLoggingInterceptor` + `TokenAuthenticator`.

- [ ] **Step 9: Checkpoint** — list files.

---

### Task 6: `NetworkMonitor`, adaptive info, orientation policy

**Files:**
- Create: `SRC/core/network/NetworkMonitor.kt`
- Create: `SRC/core/adaptive/AdaptiveInfo.kt`
- Modify: `SRC/di/BindingsModule.kt` (bind `NetworkMonitor`)
- Test: `TEST/core/adaptive/AdaptiveInfoTest.kt`, `TEST/fakes/FakeNetworkMonitor.kt`

**Interfaces (Produces):**
- `interface NetworkMonitor { val isOnline: StateFlow<Boolean> }`, `class ConnectivityNetworkMonitor`
- `enum class WidthClass { Compact, Medium, Expanded }` with `fromWidthDp(widthDp: Int)`; `data class AdaptiveInfo(widthClass, isTabletDevice, isLandscape)` with `usesTwoPane: Boolean`, `cardColumns: Int`, `AdaptiveInfo.from(widthDp, heightDp, smallestWidthDp)`; `@Composable fun rememberAdaptiveInfo(): AdaptiveInfo`
- `OrientationPolicy.requestedOrientation(smallestScreenWidthDp: Int): Int`, `isTablet(...)` (created in Task 3)

- [ ] **Step 1: Write failing tests**

`TEST/core/adaptive/AdaptiveInfoTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.adaptive

import android.content.pm.ActivityInfo
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class AdaptiveInfoTest {
    @Test
    fun `width classes follow material breakpoints`() {
        assertEquals(WidthClass.Compact, WidthClass.fromWidthDp(599))
        assertEquals(WidthClass.Medium, WidthClass.fromWidthDp(600))
        assertEquals(WidthClass.Medium, WidthClass.fromWidthDp(839))
        assertEquals(WidthClass.Expanded, WidthClass.fromWidthDp(840))
    }

    @Test
    fun `tablet landscape uses two panes and four card columns`() {
        val info = AdaptiveInfo.from(widthDp = 1280, heightDp = 800, smallestWidthDp = 800)
        assertTrue(info.usesTwoPane)
        assertTrue(info.isTabletDevice)
        assertTrue(info.isLandscape)
        assertEquals(4, info.cardColumns)
    }

    @Test
    fun `tablet portrait still two pane with three columns`() {
        val info = AdaptiveInfo.from(widthDp = 800, heightDp = 1280, smallestWidthDp = 800)
        assertTrue(info.usesTwoPane)
        assertFalse(info.isLandscape)
        assertEquals(3, info.cardColumns)
    }

    @Test
    fun `narrow multi-window is single pane with two columns`() {
        val info = AdaptiveInfo.from(widthDp = 411, heightDp = 891, smallestWidthDp = 411)
        assertFalse(info.usesTwoPane)
        assertFalse(info.isTabletDevice)
        assertEquals(2, info.cardColumns)
    }

    @Test
    fun `orientation is locked to landscape only on tablets`() {
        assertEquals(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE, OrientationPolicy.requestedOrientation(600))
        assertEquals(ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE, OrientationPolicy.requestedOrientation(599))
    }
}
```

`TEST/fakes/FakeNetworkMonitor.kt`
```kotlin
package com.noshitechinc.restaurant.fakes

import com.noshitechinc.restaurant.core.network.NetworkMonitor
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class FakeNetworkMonitor(online: Boolean = true) : NetworkMonitor {
    private val state = MutableStateFlow(online)
    override val isOnline: StateFlow<Boolean> = state

    fun setOnline(online: Boolean) {
        state.value = online
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (unresolved `WidthClass`, `NetworkMonitor`).

- [ ] **Step 3: Implement**

`SRC/core/adaptive/AdaptiveInfo.kt`
```kotlin
package com.noshitechinc.restaurant.core.adaptive

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.platform.LocalConfiguration

enum class WidthClass {
    Compact,
    Medium,
    Expanded,
    ;

    companion object {
        const val MEDIUM_MIN_DP = 600
        const val EXPANDED_MIN_DP = 840

        fun fromWidthDp(widthDp: Int): WidthClass = when {
            widthDp >= EXPANDED_MIN_DP -> Expanded
            widthDp >= MEDIUM_MIN_DP -> Medium
            else -> Compact
        }
    }
}

data class AdaptiveInfo(
    val widthClass: WidthClass,
    val isTabletDevice: Boolean,
    val isLandscape: Boolean,
) {
    val usesTwoPane: Boolean get() = widthClass != WidthClass.Compact

    val cardColumns: Int
        get() = when (widthClass) {
            WidthClass.Compact -> 2
            WidthClass.Medium -> 3
            WidthClass.Expanded -> 4
        }

    companion object {
        fun from(widthDp: Int, heightDp: Int, smallestWidthDp: Int): AdaptiveInfo = AdaptiveInfo(
            widthClass = WidthClass.fromWidthDp(widthDp),
            isTabletDevice = OrientationPolicy.isTablet(smallestWidthDp),
            isLandscape = widthDp > heightDp,
        )
    }
}

@Composable
fun rememberAdaptiveInfo(): AdaptiveInfo {
    val configuration = LocalConfiguration.current
    return remember(configuration.screenWidthDp, configuration.screenHeightDp, configuration.smallestScreenWidthDp) {
        AdaptiveInfo.from(configuration.screenWidthDp, configuration.screenHeightDp, configuration.smallestScreenWidthDp)
    }
}
```

`SRC/core/network/NetworkMonitor.kt`
```kotlin
package com.noshitechinc.restaurant.core.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import androidx.core.content.getSystemService
import com.noshitechinc.restaurant.core.common.coroutines.ApplicationScope
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.stateIn

interface NetworkMonitor {
    val isOnline: StateFlow<Boolean>
}

@Singleton
class ConnectivityNetworkMonitor @Inject constructor(
    @ApplicationContext context: Context,
    @ApplicationScope scope: CoroutineScope,
) : NetworkMonitor {
    private val manager: ConnectivityManager = requireNotNull(context.getSystemService())

    override val isOnline: StateFlow<Boolean> = callbackFlow {
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                trySend(manager.hasValidatedInternet())
            }

            override fun onLost(network: Network) {
                trySend(manager.hasValidatedInternet())
            }

            override fun onCapabilitiesChanged(network: Network, capabilities: NetworkCapabilities) {
                trySend(manager.hasValidatedInternet())
            }
        }
        manager.registerDefaultNetworkCallback(callback)
        trySend(manager.hasValidatedInternet())
        awaitClose { manager.unregisterNetworkCallback(callback) }
    }
        .distinctUntilChanged()
        .stateIn(scope, SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS), initialValue = true)

    private fun ConnectivityManager.hasValidatedInternet(): Boolean =
        getNetworkCapabilities(activeNetwork)?.let {
            it.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) &&
                it.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        } ?: false

    private companion object {
        const val STOP_TIMEOUT_MILLIS = 5_000L
    }
}
```

Add to `SRC/di/BindingsModule.kt`:
```kotlin
    @Binds
    abstract fun networkMonitor(impl: ConnectivityNetworkMonitor): NetworkMonitor
```
(imports `com.noshitechinc.restaurant.core.network.ConnectivityNetworkMonitor`, `com.noshitechinc.restaurant.core.network.NetworkMonitor`).

- [ ] **Step 4: Run tests + build — expect PASS** (`./gradlew testDevDebugUnitTest assembleDevDebug`).

- [ ] **Step 5: Checkpoint** — list files.

---

### Task 7: `core/ui` MVVM core — `LoadState`, `UiEffect`, error text, `BaseViewModel`

**Files:**
- Create: `SRC/core/ui/LoadState.kt`, `SRC/core/ui/UiEffect.kt`, `SRC/core/ui/BaseViewModel.kt`, `SRC/core/ui/error/AppErrorText.kt`
- Modify: `app/src/main/res/values/strings.xml` (error strings)
- Test: `TEST/testing/MainDispatcherRule.kt`, `TEST/core/ui/BaseViewModelTest.kt`, `TEST/core/ui/LoadStateTest.kt`

**Interfaces (Produces):**
- `sealed interface LoadState<out T> { Idle; Loading; Content(data: T); Empty; Error(error: AppError) }`, `fun <T> ApiResult<T>.toLoadState(isEmpty: (T) -> Boolean = …): LoadState<T>`
- `interface UiEffect`, `enum class MessageTone { Info, Success, Error }`, `data class ShowMessage(text: UiText, tone: MessageTone = Info) : UiEffect`, `data class ShowErrorDialog(error: AppError) : UiEffect`
- `fun AppError.toUiText(): UiText`, `@StringRes fun AppError.titleRes(): Int`
- `abstract class BaseViewModel : ViewModel()` with `val effects: Flow<UiEffect>`, `val submittingKeys: StateFlow<Set<String>>`, `fun isSubmitting(key: String): Boolean`, `protected fun sendEffect(effect: UiEffect)`, `protected fun launchSubmit(key: String, block: suspend CoroutineScope.() -> Unit): Job?`, `protected fun presentError(error: AppError)`
- String resources: `error_title_generic`, `error_title_offline`, `error_title_unavailable`, `error_no_internet`, `error_timeout`, `error_service_unavailable`, `error_session_expired`, `error_forbidden`, `error_not_found`, `error_validation`, `error_server`, `error_unknown`

- [ ] **Step 1: Write failing tests**

`TEST/testing/MainDispatcherRule.kt`
```kotlin
package com.noshitechinc.restaurant.testing

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.TestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.rules.TestWatcher
import org.junit.runner.Description

@OptIn(ExperimentalCoroutinesApi::class)
class MainDispatcherRule(
    val dispatcher: TestDispatcher = UnconfinedTestDispatcher(),
) : TestWatcher() {
    override fun starting(description: Description) = Dispatchers.setMain(dispatcher)

    override fun finished(description: Description) = Dispatchers.resetMain()
}
```

`TEST/core/ui/LoadStateTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import com.noshitechinc.restaurant.core.common.ApiResult
import com.noshitechinc.restaurant.core.common.AppError
import kotlin.test.Test
import kotlin.test.assertEquals

class LoadStateTest {
    @Test
    fun `empty list becomes Empty`() {
        assertEquals(LoadState.Empty, ApiResult.Success(emptyList<String>()).toLoadState())
    }

    @Test
    fun `non empty data becomes Content`() {
        assertEquals(LoadState.Content(listOf("a")), ApiResult.Success(listOf("a")).toLoadState())
    }

    @Test
    fun `failure becomes Error`() {
        assertEquals(LoadState.Error(AppError.Timeout), ApiResult.Failure(AppError.Timeout).toLoadState())
    }

    @Test
    fun `custom emptiness predicate is used`() {
        assertEquals(LoadState.Empty, ApiResult.Success("").toLoadState { it.isEmpty() })
    }
}
```

`TEST/core/ui/BaseViewModelTest.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import app.cash.turbine.test
import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.testing.MainDispatcherRule
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Job
import kotlinx.coroutines.test.runTest
import org.junit.Rule

class BaseViewModelTest {
    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private class TestViewModel : BaseViewModel() {
        var runs = 0

        fun submit(key: String = "save", gate: CompletableDeferred<Unit>): Job? = launchSubmit(key) {
            runs++
            gate.await()
        }

        fun submitFailing(): Job? = launchSubmit("save") { error("boom") }

        fun show(error: AppError) = presentError(error)
    }

    @Test
    fun `second submit with the same key is ignored while the first runs`() = runTest {
        val vm = TestViewModel()
        val gate = CompletableDeferred<Unit>()
        vm.submit(gate = gate)
        assertNull(vm.submit(gate = gate))
        assertEquals(1, vm.runs)
        assertTrue(vm.isSubmitting("save"))
        assertEquals(setOf("save"), vm.submittingKeys.value)
        gate.complete(Unit)
        assertFalse(vm.isSubmitting("save"))
    }

    @Test
    fun `different keys run concurrently`() = runTest {
        val vm = TestViewModel()
        val gate = CompletableDeferred<Unit>()
        vm.submit("save", gate)
        vm.submit("print", gate)
        assertEquals(setOf("save", "print"), vm.submittingKeys.value)
        gate.complete(Unit)
        assertEquals(emptySet(), vm.submittingKeys.value)
    }

    @Test
    fun `key is released when the job is cancelled`() = runTest {
        val vm = TestViewModel()
        val job = vm.submit(gate = CompletableDeferred())
        job?.cancel()
        assertFalse(vm.isSubmitting("save"))
    }

    @Test
    fun `failure releases the key and shows an error dialog`() = runTest {
        val vm = TestViewModel()
        vm.effects.test {
            vm.submitFailing()
            assertIs<AppError.Unknown>(assertIs<ShowErrorDialog>(awaitItem()).error)
        }
        assertFalse(vm.isSubmitting("save"))
    }

    @Test
    fun `connectivity errors are shown as messages`() = runTest {
        val vm = TestViewModel()
        vm.effects.test {
            vm.show(AppError.NoInternet)
            assertEquals(MessageTone.Error, assertIs<ShowMessage>(awaitItem()).tone)
        }
    }

    @Test
    fun `effects sent before collection are buffered`() = runTest {
        val vm = TestViewModel()
        vm.show(AppError.NotFound)
        vm.effects.test {
            assertEquals(ShowErrorDialog(AppError.NotFound), awaitItem())
        }
    }
}
```

- [ ] **Step 2: Run — expect FAIL** (unresolved `BaseViewModel`, `LoadState`).

- [ ] **Step 3: Add strings** to `res/values/strings.xml` (inside `<resources>`):

```xml
    <string name="error_title_generic">Something went wrong</string>
    <string name="error_title_offline">You are offline</string>
    <string name="error_title_unavailable">Service unavailable</string>
    <string name="error_no_internet">Check the internet connection and try again.</string>
    <string name="error_timeout">The server took too long to respond. Try again.</string>
    <string name="error_service_unavailable">The service is temporarily unavailable. Try again in a moment.</string>
    <string name="error_session_expired">Your session has expired. Please sign in again.</string>
    <string name="error_forbidden">You do not have permission to do this.</string>
    <string name="error_not_found">We could not find what you were looking for.</string>
    <string name="error_validation">Some details are not valid. Check them and try again.</string>
    <string name="error_server">The server had a problem. Try again.</string>
    <string name="error_unknown">An unexpected error occurred. Try again.</string>
```

- [ ] **Step 4: Implement**

`SRC/core/ui/LoadState.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import com.noshitechinc.restaurant.core.common.ApiResult
import com.noshitechinc.restaurant.core.common.AppError

sealed interface LoadState<out T> {
    data object Idle : LoadState<Nothing>
    data object Loading : LoadState<Nothing>
    data class Content<out T>(val data: T) : LoadState<T>
    data object Empty : LoadState<Nothing>
    data class Error(val error: AppError) : LoadState<Nothing>
}

fun <T> ApiResult<T>.toLoadState(
    isEmpty: (T) -> Boolean = { (it as? Collection<*>)?.isEmpty() == true },
): LoadState<T> = when (this) {
    is ApiResult.Success -> if (isEmpty(data)) LoadState.Empty else LoadState.Content(data)
    is ApiResult.Failure -> LoadState.Error(error)
}
```

`SRC/core/ui/UiEffect.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.core.common.UiText

interface UiEffect

enum class MessageTone { Info, Success, Error }

data class ShowMessage(val text: UiText, val tone: MessageTone = MessageTone.Info) : UiEffect

data class ShowErrorDialog(val error: AppError) : UiEffect
```

`SRC/core/ui/error/AppErrorText.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui.error

import androidx.annotation.StringRes
import com.noshitechinc.restaurant.R
import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.core.common.UiText

fun AppError.toUiText(): UiText = when (this) {
    AppError.NoInternet -> UiText.Resource(R.string.error_no_internet)
    AppError.Timeout -> UiText.Resource(R.string.error_timeout)
    AppError.ServiceUnavailable -> UiText.Resource(R.string.error_service_unavailable)
    AppError.SessionExpired -> UiText.Resource(R.string.error_session_expired)
    AppError.Forbidden -> UiText.Resource(R.string.error_forbidden)
    AppError.NotFound -> UiText.Resource(R.string.error_not_found)
    is AppError.Validation -> message?.let { UiText.Dynamic(it) } ?: UiText.Resource(R.string.error_validation)
    is AppError.Server -> message?.let { UiText.Dynamic(it) } ?: UiText.Resource(R.string.error_server)
    is AppError.Unknown -> UiText.Resource(R.string.error_unknown)
}

@StringRes
fun AppError.titleRes(): Int = when (this) {
    AppError.NoInternet -> R.string.error_title_offline
    AppError.ServiceUnavailable -> R.string.error_title_unavailable
    else -> R.string.error_title_generic
}
```

`SRC/core/ui/BaseViewModel.kt`
```kotlin
package com.noshitechinc.restaurant.core.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.noshitechinc.restaurant.core.common.AppError
import com.noshitechinc.restaurant.core.ui.error.toUiText
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import timber.log.Timber

abstract class BaseViewModel : ViewModel() {
    private val effectChannel = Channel<UiEffect>(Channel.BUFFERED)
    val effects: Flow<UiEffect> = effectChannel.receiveAsFlow()

    private val _submittingKeys = MutableStateFlow<Set<String>>(emptySet())
    val submittingKeys: StateFlow<Set<String>> = _submittingKeys.asStateFlow()

    fun isSubmitting(key: String): Boolean = key in _submittingKeys.value

    protected fun sendEffect(effect: UiEffect) {
        effectChannel.trySend(effect)
    }

    @Suppress("TooGenericExceptionCaught")
    protected fun launchSubmit(key: String, block: suspend CoroutineScope.() -> Unit): Job? {
        if (!tryAcquire(key)) return null
        return viewModelScope.launch {
            try {
                block()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                Timber.e(e, "Submit '%s' failed", key)
                presentError(AppError.Unknown(e))
            } finally {
                _submittingKeys.update { it - key }
            }
        }
    }

    protected fun presentError(error: AppError) {
        when (error) {
            AppError.NoInternet, AppError.Timeout -> sendEffect(ShowMessage(error.toUiText(), MessageTone.Error))
            else -> sendEffect(ShowErrorDialog(error))
        }
    }

    private fun tryAcquire(key: String): Boolean {
        while (true) {
            val current = _submittingKeys.value
            if (key in current) return false
            if (_submittingKeys.compareAndSet(current, current + key)) return true
        }
    }
}
```

- [ ] **Step 5: Run — expect PASS** (`./gradlew testDevDebugUnitTest`).

- [ ] **Step 6: Checkpoint** — list files.

---

### Task 8: Static analysis, full verification, doc sync for Plan 2

**Files:**
- Modify: `config/detekt/detekt.yml` (only as required by real findings)
- Modify (context repo): `docs/05-breakdown/sprints/sprint-0.md`, `docs/05-breakdown/modules/FOUND.md`, `PROJECT-INDEX.md`, `docs/03-context/PENDING-DECISIONS.md` (PDR-005 outcome)

- [ ] **Step 1: ktlint**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintFormat ktlintCheck --console=plain`
Expected: `BUILD SUCCESSFUL`. If `ktlintCheck` reports rules that conflict with Compose conventions, disable only that rule in `.editorconfig` with a `ktlint_standard_<rule> = disabled` line and note it in ADR-001.

- [ ] **Step 2: detekt**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew detekt --console=plain`
Expected: `BUILD SUCCESSFUL`. If detekt reports config-validation errors (renamed rules in 2.0), fix the key names printed in the error. Fix real code findings in code. If detekt cannot run at all on Kotlin 2.2.10, remove the plugin (see Task 1 Step 14), and record in PDR-005: "detekt deferred until Kotlin ≥ 2.3; ktlint + Android lint active".

- [ ] **Step 3: Full verification**

Run: `cd /home/bs01470/AndroidStudioProjects/resturant-app && ANDROID_HOME=$HOME/Android/Sdk ./gradlew ktlintCheck detekt testDevDebugUnitTest assembleDevDebug assembleStagingDebug assembleProdRelease --console=plain`
Expected: `BUILD SUCCESSFUL` (drop `detekt` from the command if PDR-005 deferred it).

- [ ] **Step 4: Doc sync** (context repo)
  - `sprint-0.md`: FOUND-001, 002, 004, 005 → Done; FOUND-003 → In progress (orientation policy done, UI in Plan 3); FOUND-019 → In progress (`launchSubmit` done, button wiring in Plan 3).
  - `modules/FOUND.md`: fill code paths and test class names for the tickets above.
  - `PROJECT-INDEX.md`: Last updated; status line "Plan 2 complete".
  - `PENDING-DECISIONS.md`: PDR-005 outcome.

- [ ] **Step 5: Checkpoint** — list files.

---

## Self-review (done at plan time)

- Spec coverage: §3 → Task 1; §4.2 (non-visual) → Task 7; §5 → Tasks 4–6; §6 → Task 3; §8 orientation → Tasks 3, 6; §10 unit tests (error mapper, safeApiCall, authenticator, formatters/validators, launchSubmit) → Tasks 2–7. Visual parts (§7, AppScaffold, Home, UI tests) → Plan 3.
- Names used by Plan 3: `BaseViewModel`, `submittingKeys`, `launchSubmit`, `presentError`, `effects`, `UiEffect`, `ShowMessage`, `ShowErrorDialog`, `MessageTone`, `LoadState`, `AppError.toUiText()`, `AppError.titleRes()`, `UiText`, `NetworkMonitor.isOnline`, `SessionManager.sessionEnded`, `rememberAdaptiveInfo()`, `AdaptiveInfo.cardColumns/usesTwoPane`, `OrientationPolicy.requestedOrientation`, `CurrencyFormatter`, `UsPhoneFormatter`, `UsPhoneValidator`, `UsAddressValidator`, `PostalAddress`, `AddressField`, `AppInfo`, `AppEnvironment`, `FakeNetworkMonitor`, `MainDispatcherRule`.

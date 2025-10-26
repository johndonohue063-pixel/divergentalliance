android {
    namespace "com.divergent.alliance"

    compileSdkVersion 34
    ndkVersion flutter.ndkVersion

            defaultConfig {
                applicationId "com.divergent.alliance"
                minSdkVersion 21
                targetSdkVersion 34
                versionCode flutterVersionCode.toInteger()
                versionName flutterVersionName
            }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
                targetCompatibility JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

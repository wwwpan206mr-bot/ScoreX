"""Configure the Flutter-generated Android project for a signed Play release."""
from pathlib import Path

path = Path("android/app/build.gradle.kts")
if not path.exists():
    raise SystemExit("Expected Flutter Kotlin Gradle template; refusing unsigned release")
text = path.read_text()
marker = "    buildTypes {"
if marker not in text or 'signingConfigs.getByName("debug")' not in text:
    raise SystemExit("Unexpected signing template; inspect before building")
signing = '''    signingConfigs {
        create("scorexUpload") {
            storeFile = file(System.getenv("SCOREX_KEYSTORE_PATH") ?: error("Missing keystore"))
            storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD") ?: error("Missing store password")
            keyAlias = System.getenv("ANDROID_KEY_ALIAS") ?: error("Missing key alias")
            keyPassword = System.getenv("ANDROID_KEY_PASSWORD") ?: error("Missing key password")
        }
    }

'''
text = text.replace(marker, signing + marker, 1)
text = text.replace('signingConfigs.getByName("debug")', 'signingConfigs.getByName("scorexUpload")')
text = text.replace("targetSdk = flutter.targetSdkVersion", "targetSdk = 36")
path.write_text(text)

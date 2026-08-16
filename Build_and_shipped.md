# 📦 BUILD & SHIPPING GUIDE — DHBH POS Android

> **Target Platform:** Android Tablets (2GB RAM, 1280x800 resolution)
> **Branch:** `android-branch`
> **Version:** `1.2.0+1`
> **Package ID:** `com.dhbh.dhbh_app`

---

## 1. 📋 Prerequisites

### System Requirements
- **OS:** Windows 10/11 (64-bit), macOS, or Linux
- **Flutter SDK:** `^3.11.5` or later
- **Android Studio:** Latest version with Android SDK
- **Java JDK:** Version 17 or higher
- **Minimum Android API:** API 21 (Android 5.0)
- **Target Android API:** API 35 (Android 15)

### Environment Setup

```bash
# Check Flutter installation
flutter doctor -v

# Ensure Android toolchain is ready
flutter doctor --android-licenses

# Verify connected devices or emulators
flutter devices
```

---

## 2. 🔧 Pre-Build Configuration

### 2.1 Update Version Numbers

Before building, update version in `pubspec.yaml`:

```yaml
version: 1.2.0+1  # Increase build number for each release
```

### 2.2 Android Manifest Permissions

Ensure `android/app/src/main/AndroidManifest.xml` has required permissions:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
<uses-permission android:name="android.permission.BLUETOOTH_SCAN"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

### 2.3 Build Configuration

Key settings in `android/app/build.gradle.kts`:

```kotlin
android {
    compileSdk = 35
    
    defaultConfig {
        applicationId = "com.dhbh.dhbh_app"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.2.0"
        
        // Optimize for 2GB RAM devices
        ndk {
            abiFilters += listOf("arm64-v8a", "armeabi-v7a")
        }
    }
    
    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}
```

---

## 3. 🏗️ Building the APK

### 3.1 Clean Build (Recommended)

```bash
# Navigate to project root
cd /path/to/dhbh_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

### 3.2 Build Output

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

**Expected APK Size:** ~40-50 MB (optimized for hdpi resources)

### 3.3 Build for Specific ABI (Optional)

To reduce APK size further, build for specific CPU architectures:

```bash
# ARM64 only (modern devices)
flutter build apk --release --target-platform android-arm64

# ARMv7 only (older devices)
flutter build apk --release --target-platform android-arm
```

### 3.4 Split APKs by ABI

```bash
flutter build apk --release --split-per-abi
```

This generates separate APKs:
- `app-armeabi-v7a-release.apk` (~25 MB)
- `app-arm64-v8a-release.apk` (~28 MB)
- `app-release.apk` (universal, ~50 MB)

---

## 4. 📱 Installing on Device

### 4.1 Via USB Debugging

```bash
# Enable USB debugging on Android tablet
# Connect device via USB
# Install APK
flutter install

# Or use adb directly
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4.2 Wireless Installation

```bash
# Connect via WiFi (ensure same network)
adb connect <device-ip>:5555
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4.3 Manual Installation

1. Transfer `app-release.apk` to tablet
2. Enable "Install from Unknown Sources" in Settings
3. Open APK file and install

---

## 5. ✅ Post-Installation Verification

### 5.1 Bluetooth Auto-Connect Test

Verify auto-connect to configured MAC addresses:
- `66:12:3f:23:ef:92`
- `66:22:0E:80:81:CC`

**Steps:**
1. Launch app and login
2. Check Bluetooth status indicator in AppBar
3. Verify connection log shows successful auto-connect
4. Print test receipt

### 5.2 Print Layout Verification

Compare Android print output with Windows:
- Header (DHBH logo, branch name, timestamp)
- Transaction details (order number, cashier)
- Product list (name, qty, price, total)
- Payment breakdown (subtotal, discount, total, paid, change)
- Footer (customer names, therapist names, thank you message)

### 5.3 Performance Checks

On 2GB RAM tablet with 1280x800 screen:
- App launch time: < 3 seconds
- UI responsiveness: No lag during scrolling
- Memory usage: < 400 MB (check via Developer Options)
- No OOM crashes during extended use

---

## 6. 🚀 Publishing to Production

### 6.1 Generate App Bundle (Play Store)

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### 6.2 Signing Configuration

Create `android/key.properties`:

```properties
storePassword=<keystore-password>
keyPassword=<key-password>
keyAlias=<key-alias>
storeFile=<path-to-keystore>
```

Add to `android/app/build.gradle.kts`:

```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 6.3 Create Keystore

```bash
keytool -genkey -v -keystore ~/dhbh-upload-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias dhbh-key
```

---

## 7. 🐛 Troubleshooting

### Build Fails with Gradle Error

```bash
# Clear Gradle cache
cd android
./gradlew clean
cd ..

# Rebuild
flutter clean && flutter pub get && flutter build apk --release
```

### Bluetooth Permission Denied

Ensure runtime permissions are granted:
- Go to Settings → Apps → DHBH POS → Permissions
- Enable Location and Nearby Devices permissions

### App Crashes on Startup

Check logs:
```bash
adb logcat | grep -i dhbh
```

Common causes:
- Missing Supabase configuration
- Network connectivity issues
- Insufficient memory (check `largeHeap` flag in manifest)

### Print Layout Mismatch

Verify `ThermalPrinterService.generateReceipt()` uses same template as Windows:
- Check line widths (48 characters for 80mm paper)
- Verify ESC/POS commands for bold, alignment, line feeds
- Compare output byte-by-byte if needed

---

## 8. 📊 Build Metrics

| Metric | Target | Notes |
|---|---|---|
| APK Size (Universal) | < 60 MB | With hdpi resource restriction |
| APK Size (Split ARM64) | < 35 MB | Recommended for distribution |
| App Launch Time | < 3s | Cold start on 2GB RAM device |
| Memory Usage (Idle) | < 200 MB | After initial load |
| Memory Usage (Active) | < 400 MB | During transactions |
| Frame Rate | 60 FPS | Smooth scrolling expected |

---

## 9. 📝 Release Checklist

Before shipping:

- [ ] Version number updated in `pubspec.yaml`
- [ ] All tests passing (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Bluetooth auto-connect tested with both MAC addresses
- [ ] Print layout verified against Windows output
- [ ] Performance tested on target device (2GB RAM, 1280x800)
- [ ] Memory pressure scenarios tested
- [ ] Supabase connectivity verified
- [ ] All CRUD operations functional
- [ ] Backup feature tested
- [ ] Documentation updated (`PROJECT_CONTEXT.md`, `AGENTS.md`)
- [ ] Changelog entry added
- [ ] Git commit with descriptive message
- [ ] Tag created: `git tag -a v1.2.0+1 -m "Android release"`
- [ ] Branch pushed to GitHub

---

## 10. 🔗 Related Documentation

- **Project Context:** `PROJECT_CONTEXT.md` — Full project overview
- **Agent Notes:** `AGENTS.md` — Development history and decisions
- **Database Schema:** `Database_details.md` — Supabase schema reference
- **User Guide:** `USER_GUIDE.md` — End-user operational manual
- **README:** `README.md` — Quick start guide

---

## 11. 📞 Support

For issues or questions:
- Check `%TEMP%\dhbh_flutter_errors.log` for crash logs
- Review `AGENTS.md` for recent changes and known issues
- Contact development team with device model and Android version

**Last Updated:** 2026-08-15  
**Document Version:** 1.0  
**App Version:** 1.2.0+1

# Android SDK Setup for Flutter

## Current Status
- ❌ Android SDK is not installed
- ✅ Flutter is installed (3.47.1)
- ✅ Windows is set up correctly

## Quick Setup (2 Options)

### Option 1: Install Android Studio (Recommended)

1. **Download Android Studio**
   - Go to: https://developer.android.com/studio
   - Download for Windows
   - Run the installer

2. **First Launch Setup**
   - Android Studio will automatically install:
     - Android SDK
     - Android SDK Platform-Tools
     - Android Emulator
   - Accept licenses when prompted
   - Wait for downloads to complete (10-15 minutes)

3. **Verify Installation**
   ```bash
   flutter doctor
   ```
   - Should show `[√] Android toolchain`

4. **Proceed with Building**
   ```bash
   cd mobile
   flutter build appbundle --release
   ```

### Option 2: Command-Line Setup (Advanced)

1. **Install Android Command-Line Tools Only**
   - Download: https://developer.android.com/studio#downloads
   - Scroll to "Command line tools only"
   - Extract to: `C:\Android\cmdline-tools\latest`

2. **Set ANDROID_HOME**
   ```powershell
   # Open PowerShell as Admin
   [Environment]::SetEnvironmentVariable("ANDROID_HOME", "C:\Android", "User")
   
   # Add to PATH
   $path = [Environment]::GetEnvironmentVariable("PATH", "User")
   [Environment]::SetEnvironmentVariable("PATH", "$path;C:\Android\cmdline-tools\latest\bin;C:\Android\platform-tools", "User")
   ```

3. **Install SDK Components**
   ```bash
   sdkmanager --install "platforms;android-34" "platform-tools" "build-tools;34.0.0"
   ```

4. **Accept Licenses**
   ```bash
   sdkmanager --licenses
   # Type 'y' for each license
   ```

5. **Verify**
   ```bash
   flutter doctor
   ```

---

## After Android SDK is Installed

Run this command to build the app bundle:

```bash
cd c:\Users\MohdA\Downloads\challenge-education-app-school\challenge-education-app-school\mobile

# Clean build files
flutter clean

# Get dependencies
flutter pub get

# Build signed app bundle (creates app-release.aab)
flutter build appbundle --release
```

**Expected Output:**
```
✓ Built mobile/build/app/outputs/bundle/release/app-release.aab
```

---

## Troubleshooting

**Error: "Unable to locate Android SDK"**
- Restart terminal/IDE after installing Android Studio
- Restart computer if needed
- Run: `flutter doctor --android-licenses` to accept licenses

**Error: "Could not find gradle.properties"**
- Run: `flutter clean` first
- Then: `flutter pub get`

**Error: "Invalid SDK version"**
- Run: `flutter doctor` to see what version is needed
- Android Studio will suggest installing missing components

---

## Estimated Time
- Download Android Studio: 5-10 minutes (depends on internet)
- First install: 10-15 minutes
- Build app bundle: 2-5 minutes

**Total: 20-30 minutes to first build**

---

## Next Steps After Android SDK is Ready

1. Build app bundle
2. Follow `GOOGLE_PLAY_UPLOAD_GUIDE.md` to upload to Google Play
3. Test on internal testing track
4. Submit for review

---

**Note:** Once Android SDK is installed, you can build whenever needed without re-installing.

# Install Android Studio - Quick Guide

## Issue Encountered
The command-line Android SDK setup encountered a Java version mismatch. The simplest solution is to install Android Studio, which handles everything automatically.

## Why Android Studio?
✅ Handles all dependencies (including correct Java version)
✅ Automatic Android SDK installation
✅ No manual configuration needed
✅ Works out of the box
⏱️ Takes 5-10 minutes total

## Download & Install

### Step 1: Download
Go to: https://developer.android.com/studio

Click **"Download Android Studio Hedgehog"** (or latest version)

### Step 2: Run Installer
1. Run the downloaded `.exe` file
2. Click **Next** to start installation
3. Keep all default settings
4. Click **Install**

### Step 3: First Launch Setup
When Android Studio launches for the first time:
1. It will offer to install Android SDK
2. Select **Standard** (default) setup
3. Accept licenses when prompted
4. Let it download and install (10-15 minutes)
5. Close Android Studio when done

### Step 4: Verify
Open PowerShell and run:
```powershell
flutter doctor
```

Should show:
```
[✓] Android toolchain - develop for Android devices
```

## That's It!
Once `flutter doctor` shows ✓, you can build the app bundle.

---

## Alternative: Minimal Installation
If you don't want the full Android Studio IDE:

1. During installation, choose **Custom** setup
2. Uncheck "Android Studio" (IDE)
3. Keep Android SDK, Android Emulator, Platform-Tools checked
4. Install and proceed

This gives you just the SDK without the IDE (~1 GB vs 4 GB).

---

## Next Steps After Installation

```powershell
cd c:\Users\MohdA\Downloads\challenge-education-app-school\challenge-education-app-school\mobile

flutter clean
flutter pub get
flutter build appbundle --release
```

Creates: `build/app/outputs/bundle/release/app-release.aab` (50-100 MB)

---

## Download Link
https://developer.android.com/studio

**Estimated Time:** 20-30 minutes total (mostly downloading)

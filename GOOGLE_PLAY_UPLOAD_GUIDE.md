# Google Play Upload Guide

## Build Status
✅ Building signed App Bundle (`app-release.aab`)
- Location: `mobile/build/app/outputs/bundle/release/app-release.aab`
- Signing: Configured with `upload-keystore.jks`

---

## Step 1: Google Play Developer Account

### Prerequisites
- [ ] Google account (personal or business)
- [ ] $25 one-time registration fee (credit/debit card)
- [ ] Developer identity (name and country)

### Setup
1. Go to [Google Play Console](https://play.google.com/console)
2. Sign in with your Google account
3. Accept Developer Agreement and Program Policies
4. Complete payment ($25 one-time)
5. Fill out account details (name, email, address, phone)
6. Set up merchant account (for payment processing)

---

## Step 2: Create New App

### In Google Play Console
1. Click **"Create app"**
2. App name: `Challenge Education` or `ساحة التنافس`
3. Default language: English (or Arabic if preferred)
4. App category: **Education**
5. App type: **Application**
6. Content rating: Select "Google Play's policy on mature content" → Continue
7. Target audience: Students, Teachers, Parents
8. Click **"Create app"**

---

## Step 3: Complete Store Listing

### Main Info
- **App title:** Challenge Education
- **Short description (80 chars max):**
  > "Arabic educational challenge arena with competitive team gaming"
  
- **Full description (4000 chars max):**
  ```
  Challenge Education - ساحة التنافس
  
  An innovative Arabic educational application designed to make learning 
  engaging and competitive. Students can:
  
  ✓ Challenge themselves across different subjects and grades
  ✓ Compete in real-time team challenges
  ✓ Track progress with interactive scoreboards
  ✓ Practice with curated question packages
  ✓ Experience gamified learning with dice rolls and timers
  
  Features:
  - Full Arabic RTL (Right-to-Left) interface
  - Tablet and phone optimized layouts
  - Secure authentication
  - Interactive question challenges
  - Team scoring and rankings
  - Countdown timers for timed challenges
  
  Perfect for:
  - Students preparing for exams
  - Teachers creating interactive lessons
  - Educational institutions building engagement
  - Parents monitoring learning progress
  
  Subjects include: Mathematics, Science, Languages, Social Studies, and more.
  ```

### Graphics & Media

#### Required Images:
1. **App Icon (512x512 PNG)**
   - Use: `mobile/assets/images/logo.png` (resize to 512x512)
   - Must have no transparent areas
   - Command: 
   ```bash
   # Using ImageMagick if available
   convert mobile/assets/images/logo.png -resize 512x512 -background white -gravity center -extent 512x512 app_icon_512.png
   ```

2. **Feature Graphic (1024x500 PNG)**
   - Should showcase app's main features
   - Text: "Challenge Education", "Learn Together, Compete Smart"
   - Colors: Use brand colors from app
   - Can be created in Canva or similar tools

3. **Screenshots (Phone)**
   - Minimum: 2, Recommended: 5
   - Size: 1080x1920 px (or 1440x2560 px)
   - Should show:
     - Login/splash screen
     - Grade & subject selection
     - Challenge arena gameplay
     - Scoreboard/results
     - Question interface
   - Add text overlays explaining features
   - Languages: English + Arabic versions recommended

4. **Screenshots (Tablet) - Optional**
   - Size: 2560x1600 px
   - Show responsive layout benefits

#### How to Get Screenshots:
- **Option 1:** Run on Android emulator/device
  ```bash
  flutter run -d <device_id>
  # Take screenshots using device's screenshot feature
  ```
- **Option 2:** Use Android Studio's screenshot tool
- **Option 3:** Record a video and capture frames

### Content Rating

1. Click **"Content rating"**
2. Email: Use your email
3. Category: Select **"Education"**
4. Answer questionnaire (few minutes):
   - Does app contain violence? No
   - Does app contain sexual content? No
   - Does app contain profanity? No
   - Does app request personal information? Yes → "Student information for login"
   - Does app have ads? No
5. Submit → Get rating certificate

### Privacy Policy

**Required!** Create privacy policy at:
- [Termly](https://termly.io) (free trial)
- [Privacy Policy Generator](https://www.privacy-policy-template.com)

**Include:**
- What data you collect (login credentials, progress)
- How you use it (authentication, analytics)
- How you protect it (encrypted storage)
- User rights (account deletion, data access)

Upload as PDF or link to webpage in Google Play Console.

---

## Step 4: Configure App Details

### Pricing & Distribution
1. **Pricing:** Select "Free"
2. **Countries:** Select where app is available
   - Start with: United States, United Kingdom, India, Arab countries
3. **Device categories:** Check Phone, Tablet
4. **Minimum Android version:** Android 5.0 (API 21)
5. **Required permissions:** Check if all are justified

### App Features
Verify:
- [ ] Payments: No (unless you add in-app purchases later)
- [ ] Ads: No (unless you add ad networks)
- [ ] Installs external content: No

### Permissions
The app requests:
- `INTERNET` → For API calls
- `CAMERA` (if used) → Document specific use
- `STORAGE` (if applicable)

Review and ensure all are necessary.

---

## Step 5: Upload App Bundle

### In Google Play Console

#### Testing First (Recommended)
1. Go to **"Testing"** → **"Internal testing"**
2. Create release:
   - Click **"Create new release"**
   - Upload `mobile/build/app/outputs/bundle/release/app-release.aab`
   - Add release notes: "Initial internal testing"
   - Review app metadata
   - Click **"Save"**
3. Add testers:
   - Enter Gmail addresses of people to test
   - They'll receive email with test link
   - Get feedback before public release

#### Production Release
1. Go to **"Production"**
2. Create release:
   ```
   Upload File: app-release.aab
   Release Name: Version 1.0.0
   Release Notes: 
   - Initial launch of Challenge Education
   - Full Arabic support
   - Competitive team challenges
   - Interactive question system
   ```
3. Review all app details
4. Click **"Next"** → **"Review"**
5. Accept terms → **"Submit for review"**

---

## Step 6: App Review

### Review Timeline
- **Duration:** 1-24 hours (usually a few hours)
- **Outcome:** Email notification
- **Common Rejection Reasons:**
  - Privacy policy missing
  - Misleading app description
  - Broken functionality
  - Policy violations

### If Rejected
1. Read rejection reason carefully
2. Fix the issue
3. Update version code (e.g., `1.0.0+2`)
4. Rebuild: `flutter build appbundle --release`
5. Upload new bundle → Resubmit

### If Approved
🎉 App is live on Google Play!
- Show up in search results
- Can be downloaded by anyone in selected countries
- Can update anytime by uploading new versions

---

## Versioning for Future Updates

### Update Version Before Each Release
Edit `mobile/pubspec.yaml`:
```yaml
version: 1.0.0+1  # Format: versionName+versionCode
```

**For version 1.0.1:**
```yaml
version: 1.0.1+2  # versionName increases, versionCode increases
```

**Rules:**
- `versionName`: User-facing version (1.0.0)
- `versionCode`: Internal build number (must always increase)
- Always increment `versionCode`, or upload will fail

---

## Rollout Strategy

### Staged Rollout (Recommended)
1. Upload to internal testing
2. Get feedback from 10-20 testers
3. Fix critical bugs
4. Upload to production with staged rollout:
   - Start at 5% users (1-2 hours)
   - Monitor crash reports
   - Increase to 25% (4 hours)
   - Increase to 50% (12 hours)
   - Increase to 100% (24+ hours)

This prevents app crashing for all users.

---

## Post-Launch Monitoring

### Google Play Console Dashboard
- **Installs:** How many users downloaded
- **Ratings & Reviews:** User feedback
- **Crashes & ANRs:** Technical issues
- **Vitals:** Performance metrics
- **User Acquisition:** Where users come from

### Common Issues to Monitor
- App crashes (fix immediately)
- Negative reviews (respond professionally)
- Low ratings (identify patterns)
- Performance regressions (test new versions)

---

## Checklist: Before Submitting

- [ ] Google Play Developer account created and paid
- [ ] App bundle built: `app-release.aab`
- [ ] App name decided
- [ ] Short description written (80 chars)
- [ ] Full description written (2000+ chars)
- [ ] Privacy policy created and linked
- [ ] App icon prepared (512x512)
- [ ] Feature graphic prepared (1024x500)
- [ ] Screenshots taken and prepared (min 2, max 8)
- [ ] Content rating questionnaire completed
- [ ] All required fields in Google Play Console filled
- [ ] App tested on internal testing track
- [ ] Version code incremented in `pubspec.yaml`
- [ ] App details reviewed for accuracy

---

## Quick Command Reference

```bash
# Get dependencies
flutter pub get

# Build signed app bundle
flutter build appbundle --release

# Check build output
ls mobile/build/app/outputs/bundle/release/

# Verify signing
# (Google Play Console will verify when uploaded)

# Update version
# Edit: mobile/pubspec.yaml
# Change: version: 1.0.0+X (increment X)

# Rebuild after version change
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## Support & Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter Build & Release](https://docs.flutter.dev/deployment/android)
- [App Store Optimization Tips](https://play.google.com/about/developer-content-policy)
- [Privacy Policy Generator](https://termly.io)

---

**Status:** Ready to upload! Follow steps 1-6 above to complete your Google Play launch. 🚀

# Google Play Console Setup - Complete Guide

## ✓ Completed Steps

### 1. Code Repository
- **Status**: ✓ Complete
- Code pushed to: `https://github.com/inoor19/challenge-education-app`
- Branch: `main`
- Commits: Initial Flutter app uploaded

### 2. Google Play Credentials  
- **Status**: ✓ Complete
- Service account JSON file stored in GitHub Secrets as `GOOGLE_PLAY_KEY_JSON`
- Package name: `com.challenge_education.app`

### 3. Android App Bundle (AAB)
To build the app bundle locally before uploading:

```bash
cd mobile
flutter build appbundle --release
```

The app bundle will be at: `mobile/build/app/outputs/bundle/release/app-release.aab`

## Remaining Steps: Manual Google Play Console Setup

### Step 1: Create Google Play Developer Account (if not done)
1. Go to https://play.google.com/console
2. Sign in with your Google account (alnoor20019@gmail.com)
3. Create developer account (one-time $25 fee)
4. Accept agreements

### Step 2: Create App in Google Play Console
1. Click "Create app"
2. App name: **Challenge Education**
3. Default language: **English**
4. App type: **App**
5. Category: **Education**
6. Audience: **Everyone**
7. Click "Create"

### Step 3: Fill in App Listing

#### Basic Info
- **App name**: Challenge Education (ساحة التنافس)
- **Short description** (80 chars max):
  ```
  Arabic educational challenge arena with competitive team gaming
  ```

- **Full description**:
  ```
  Challenge Education is an interactive educational platform designed for students of all ages. 
  
  Features:
  • Competitive team-based challenges
  • Real-time scoring and rankings
  • Customizable question packages
  • Arabic language support (RTL)
  • Multiple difficulty levels
  • Progress tracking and analytics
  • Secure authentication
  
  Our mission is to make learning engaging and fun through gamification and peer competition. 
  Teachers and educators can create custom challenge packages, while students compete individually 
  and as part of teams to reinforce learning objectives.
  
  Perfect for:
  - Classroom supplementary learning
  - After-school educational programs
  - Student competitions
  - Remote learning and education
  
  Download now and join the challenge arena!
  ```

#### Category & Ratings
- **Category**: Education
- **Content Rating**: Click "Fill questionnaire" and complete all questions
  - Target audience: Young children, Children, Teens, Adults

#### Branding
- Add app icon (512x512 PNG)
- Add screenshots (minimum 2, recommended 5-8):
  - Splash screen
  - Login/signup screen
  - Dashboard/home screen
  - Challenge creation screen
  - Results/scoring screen

### Step 4: Add Release Notes
1. Click "Release notes" in left menu
2. Add for version 1.0.0:
   ```
   Welcome to Challenge Education v1.0.0!
   
   Initial Release Features:
   - Create and join challenges
   - Real-time scoring
   - Team competitions
   - Progress tracking
   - Arabic language support
   
   This is our first release - thank you for your feedback!
   ```

### Step 5: Set Up Pricing
1. Click "Setup" → "Pricing and distribution"
2. Countries: Select countries where you want to offer the app
3. Price: Free (or select paid if desired)
4. Content rating: Complete the questionnaire
5. Permissions: Review and approve required permissions

### Step 6: Upload App Bundle

#### Option A: Web Upload (Recommended)
1. Go to "Testing" → "Internal testing"
2. Click "Create new release"
3. Upload `app-release.aab` from:
   ```
   mobile/build/app/outputs/bundle/release/app-release.aab
   ```
4. Add release notes for version 1.0.0
5. Review and publish to internal testing track

#### Option B: Automated Upload
If you get a GitHub Personal Access Token with `workflow` scope:
1. Create token at: https://github.com/settings/tokens
2. Select scopes:
   - `repo` (full control of private repositories)
   - `workflow` (actions)
3. Replace token in GitHub and push workflow file
4. Tag the release: `git tag v1.0.0 && git push origin v1.0.0`
5. GitHub Actions will automatically build and upload

### Step 7: Privacy Policy & Compliance
1. Go to "Setup" → "App content"
2. Add privacy policy URL (create one at: https://www.privacypolicygenerator.info)
3. Add terms of service (if applicable)
4. Fill in content rating questionnaire

### Step 8: Review & Submit
1. Check "Release checklist" - ensure all required fields are complete
2. Go to "Overview" and verify all information
3. Click "Review app" to submit for Google Play Review
4. Expected review time: 24-48 hours

## App Details for Google Play

- **Package Name**: `com.challenge_education.app`
- **Target SDK**: 35
- **Min SDK**: 24
- **Permissions**: Internet, Storage (if needed for offline content)
- **Languages**: Arabic, English
- **Countries**: Middle East, North Africa (configure as needed)

## Troubleshooting

### App Bundle Upload Fails
1. Ensure Java 21 is installed
2. Run: `flutter clean && flutter pub get`
3. Rebuild: `flutter build appbundle --release`
4. Check file size is under 100MB (typical AAB: 30-50MB)

### Content Rating Issues
- Complete the content rating questionnaire thoroughly
- Ensure no adult content is referenced
- Fill in target demographics correctly

### Privacy Policy Required
- Go to https://www.privacypolicygenerator.info
- Generate a policy for your app
- Host it on a web server or use services like firebasestorage.googleapis.com
- Add URL in Google Play Console

## Useful Links

- Google Play Console: https://play.google.com/console
- Flutter Documentation: https://flutter.dev/docs
- Android Documentation: https://developer.android.com
- Play Store Policies: https://play.google.com/about/storelisting/
- Content Rating Questionnaire: https://support.google.com/googleplay/answer/188189

## Next Steps

1. **Immediate**: Log into Google Play Console and create app
2. **Day 1-2**: Fill in all app listing details and upload screenshots
3. **Day 2**: Upload app bundle
4. **Day 3**: Submit for review
5. **Day 3-5**: Wait for review approval
6. **Day 5+**: App goes live on Google Play!

---

**Support Note**: All app data, credentials, and source code are secured in GitHub. 
You can always rebuild and resubmit updated versions using the same process.

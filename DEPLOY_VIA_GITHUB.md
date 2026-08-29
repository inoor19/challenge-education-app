# Deploy to Google Play via GitHub Actions

Due to local Java/Gradle compatibility issues, the easiest solution is to use **GitHub Actions** which has a proper pre-configured environment.

## What You Need To Do:

### Step 1: Add GitHub Actions Workflow (One Time)

Go to: https://github.com/inoor19/challenge-education-app

1. Click **Add file** → **Create new file**
2. Name: `.github/workflows/deploy-google-play.yml`
3. Paste this content:

```yaml
name: Deploy to Google Play

on:
  push:
    tags:
      - 'v*'

env:
  FLUTTER_VERSION: '3.27.3'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}

      - name: Get Flutter dependencies
        run: flutter pub get
        working-directory: mobile

      - name: Build Android App Bundle
        run: flutter build appbundle --release
        working-directory: mobile

      - name: Upload to Google Play
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_KEY_JSON }}
          packageName: com.challenge_education.app
          releaseFiles: 'mobile/build/app/outputs/bundle/release/app-release.aab'
          track: internal
          status: draft
```

4. Commit with message: "Add GitHub Actions workflow"

### Step 2: Trigger Build & Upload

After adding the workflow, run these commands:

```bash
git tag v1.0.0
git push origin v1.0.0
```

**GitHub Actions will automatically:**
- Build the app in the cloud (proper Java/Gradle setup)
- Upload to Google Play Internal Testing
- Send notification when done

---

## Timeline

1. Add workflow file to GitHub (5 minutes)
2. Run: `git tag v1.0.0 && git push origin v1.0.0` (1 minute)
3. GitHub builds & uploads (5-10 minutes)
4. App appears in Google Play Internal Testing
5. Fill Google Play Console details
6. Submit for review

---

## Fill Google Play Console Details (While GitHub builds)

Use content from `GOOGLE_PLAY_READY_TO_PASTE.md`:

1. Go to https://play.google.com/console
2. Click your "Challenge Education" app
3. Go to **Store Listing**
4. Fill in:
   - Short description
   - Full description
   - Category: Education
   - Privacy policy
   - Content rating questionnaire
5. Upload screenshots (5-8 images, 1080x1920 pixels)

---

## Submit for Review

1. After GitHub finishes uploading (check Actions tab)
2. Verify app in Google Play Internal Testing
3. Go to **Overview** tab
4. Click **Submit for review**
5. Wait 24-48 hours for approval

---

## Important Notes

✓ Google Play credentials are secure in GitHub Secrets
✓ GitHub Actions environment has proper Java/Gradle setup
✓ No more local build issues
✓ Automated process saves time

---

**Ready to proceed? Follow the steps above!**

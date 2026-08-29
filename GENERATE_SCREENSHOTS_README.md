# Generate Screenshots - Automatic PNG Export

## 🎯 What This Does

Automatically converts the HTML mockups to **8 professional PNG screenshot files** ready for Google Play Console.

---

## 📋 Requirements

- Node.js installed (from https://nodejs.org/)
- Internet connection (first run only)

---

## 🚀 How to Use

### Windows

**Double-click:** `generate-screenshots.bat`

That's it! The script will:
1. ✅ Check for Node.js
2. ✅ Install Puppeteer (if needed)
3. ✅ Generate 8 PNG files
4. ✅ Save to `./screenshots/` folder

### Mac/Linux

```bash
chmod +x generate-screenshots.sh
node generate-screenshots.js
```

Or simply:
```bash
node generate-screenshots.js
```

---

## 📁 What You'll Get

After running the script, check the `screenshots/` folder:

```
screenshots/
├── 01_login_screen.png          (1080x1920)
├── 02_home_dashboard.png        (1080x1920)
├── 03_challenge_setup.png       (1080x1920)
├── 04_live_quiz.png             (1080x1920)
├── 05_results_screen.png        (1080x1920)
├── 06_leaderboard.png           (1080x1920)
├── 07_team_screen.png           (1080x1920)
└── 08_settings.png              (1080x1920)
```

---

## ✅ Perfect for Google Play

- ✅ Correct dimensions: 1080 x 1920 pixels
- ✅ PNG format (accepted by Google)
- ✅ Professional design
- ✅ All 8 required screenshots
- ✅ Ready to upload immediately

---

## 📤 Upload to Google Play

1. **Go to:** Google Play Console → Your App → Store Listing
2. **Scroll to:** Screenshots section
3. **Click:** "Add Screenshots"
4. **Select all 8 PNG files** from `screenshots/` folder
5. **Arrange** in order if needed
6. **Save** and continue

---

## 🔧 Troubleshooting

### Error: Node.js not found

**Solution:** Install Node.js from https://nodejs.org/

### Error: npm command not found

**Solution:** 
- Close and reopen the terminal
- Or restart your computer after installing Node.js

### Screenshots are blank/white

**Solution:**
- Wait 30 seconds for HTML to load
- Check internet connection
- Try running again

### Permission denied (Mac/Linux)

**Solution:**
```bash
chmod +x generate-screenshots.js
node generate-screenshots.js
```

---

## 🎨 Customizing Screenshots

If you want to edit the mockups:

1. Open `screenshots-mockup.html` in a text editor
2. Modify the content (text, colors, layout)
3. Run `generate-screenshots.bat` again
4. New PNG files will be generated

---

## ⏱️ How Long Does It Take?

- First run: ~2 minutes (installs Puppeteer)
- Subsequent runs: ~30 seconds

---

## 📊 File Information

Each PNG screenshot:
- **Resolution:** 1080 x 1920 pixels (9:16 aspect ratio)
- **Format:** PNG
- **File size:** ~30-50 KB
- **Quality:** High resolution, professional

---

## 🎯 Next Steps After Generation

1. ✅ Generate screenshots (this script)
2. ⏳ Go to Google Play Console
3. ⏳ Store Listing → Screenshots
4. ⏳ Upload all 8 PNG files
5. ⏳ Fill store listing (use GOOGLE_PLAY_READY_TO_PASTE.md)
6. ⏳ Submit for review
7. ⏳ App goes live in 24-48 hours!

---

## 💡 Pro Tips

- **Keep backups:** Copy `screenshots/` folder before changes
- **Batch upload:** Upload all 8 at once to Google Play
- **Preview:** Check screenshots in Google Play preview before submitting
- **Device preview:** See how screenshots look on different phones

---

## 🆘 Still Having Issues?

1. Make sure you have internet connection
2. Check that `screenshots-mockup.html` exists in the same folder
3. Try deleting `node_modules/` folder and running again
4. Check that you have permission to write files

---

## 📝 Script Details

**Files Used:**
- `screenshots-mockup.html` - Source for screenshots
- `generate-screenshots.js` - Node.js script that generates PNGs
- `generate-screenshots.bat` - Windows one-click runner

**Requires:**
- Node.js v14+ 
- Puppeteer library (auto-installed)

---

## ✨ You're All Set!

Just run the script and you'll have professional app screenshots ready for Google Play! 🚀

**Time to deploy:** ~1 hour total
**App live:** 24-48 hours after submission

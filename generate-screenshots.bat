@echo off
REM Challenge Education - Generate Screenshots
REM Generates PNG screenshots from HTML mockups

echo.
echo ╔════════════════════════════════════════════╗
echo ║  Generating App Screenshots...             ║
echo ╚════════════════════════════════════════════╝
echo.

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js is not installed!
    echo.
    echo Please install Node.js from: https://nodejs.org/
    echo Then run this script again.
    echo.
    pause
    exit /b 1
)

echo ✅ Node.js found
echo.

REM Check if puppeteer is installed
if not exist "node_modules\puppeteer" (
    echo Installing Puppeteer (required for screenshot generation)...
    call npm install puppeteer
    if %errorlevel% neq 0 (
        echo ❌ Failed to install Puppeteer
        pause
        exit /b 1
    )
    echo.
)

echo ✅ Puppeteer is ready
echo.

REM Run the screenshot generator
echo Running screenshot generator...
echo.
node generate-screenshots.js

if %errorlevel% equ 0 (
    echo.
    echo ✅ SUCCESS! Screenshots generated.
    echo.
    echo 📁 Check the 'screenshots' folder for your PNG files
    echo.
    echo 📋 Next steps:
    echo 1. Go to Google Play Console
    echo 2. Store Listing ^> Screenshots
    echo 3. Upload all 8 PNG files
    echo 4. Fill store listing from GOOGLE_PLAY_READY_TO_PASTE.md
    echo 5. Submit for review
    echo.
) else (
    echo.
    echo ❌ Error generating screenshots
    echo.
)

pause

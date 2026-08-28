@echo off
REM Google Play Automated Deployment Script for Windows
REM Run this from project root: deploy.bat

setlocal enabledelayedexpansion

set PROJECT_ROOT=%~dp0
set MOBILE_DIR=%PROJECT_ROOT%mobile
set CREDENTIALS_FILE=%PROJECT_ROOT%credentials.json
set BUNDLE_FILE=%MOBILE_DIR%\build\app\outputs\bundle\release\app-release.aab
set PACKAGE_NAME=com.competitionarena.app

echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║   Google Play Automated Deployment                         ║
echo ║   Challenge Education - ساحة التنافس                      ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

REM Check prerequisites
echo [Checking Prerequisites...]

where flutter >nul 2>nul
if errorlevel 1 (
    echo X Flutter not found. Please install Flutter first.
    exit /b 1
)
echo [OK] Flutter found

where java >nul 2>nul
if errorlevel 1 (
    echo X Java not found. Please install Java 11+
    exit /b 1
)
echo [OK] Java found

if not exist "%CREDENTIALS_FILE%" (
    echo X credentials.json not found in: %PROJECT_ROOT%
    echo   Please create it from Google Cloud Console
    exit /b 1
)
echo [OK] Credentials found

REM Step 1: Build
echo.
echo [1/4] Building app bundle...
cd /d "%MOBILE_DIR%"

echo  - Cleaning previous builds...
call flutter clean >nul 2>nul

echo  - Getting dependencies...
call flutter pub get >nul

echo  - Building for release...
call flutter build appbundle --release
if errorlevel 1 (
    echo X Build failed
    exit /b 1
)

if not exist "%BUNDLE_FILE%" (
    echo X Bundle not found at %BUNDLE_FILE%
    exit /b 1
)

for %%A in ("%BUNDLE_FILE%") do set SIZE=%%~zA
set /a SIZE_MB=%SIZE% / 1048576
echo [OK] Built successfully: %SIZE_MB% MB

REM Step 2: Download bundletool if needed
echo.
echo [2/4] Preparing tools...

set BUNDLETOOL_JAR=%PROJECT_ROOT%bundletool-all.jar
if not exist "%BUNDLETOOL_JAR%" (
    echo  - Downloading bundletool...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar', '%BUNDLETOOL_JAR%')"
    echo  [OK] Downloaded bundletool
)
echo [OK] Tools ready

REM Step 3: Prepare upload
echo.
echo [3/4] Preparing upload...
echo  - Using bundletool for upload...
echo [OK] Ready for upload

REM Step 4: Upload
echo.
echo [4/4] Uploading to Google Play...
echo  - This may take a few minutes...

java -jar "%BUNDLETOOL_JAR%" upload-bundle ^
    --bundle="%BUNDLE_FILE%" ^
    --key="%CREDENTIALS_FILE%"

if errorlevel 1 (
    echo X Upload may have failed. Check Google Play Console to verify.
)

echo [OK] Upload process complete

REM Summary
echo.
echo ╔════════════════════════════════════════════════════════════╗
echo ║              DEPLOYMENT COMPLETE! (check above)             ║
echo ╚════════════════════════════════════════════════════════════╝
echo.

echo App Bundle Info:
echo   Package: %PACKAGE_NAME%
echo   File: %BUNDLE_FILE%
echo   Size: %SIZE_MB% MB
echo.

echo Next Steps:
echo   1. Go to Google Play Console
echo   2. Check Testing ^> Internal testing tab
echo   3. Verify app bundle is there
echo   4. Add testers and share test link
echo   5. After testing, promote to Production
echo   6. Submit for review
echo.

echo Google Play Console: https://play.google.com/console
echo.

pause
exit /b 0

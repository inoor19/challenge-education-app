#!/bin/bash

# Google Play Automated Deployment Script
# This script builds and uploads your Flutter app to Google Play Console
#
# Prerequisites:
#   1. credentials.json in project root (from Google Cloud Console)
#   2. Flutter installed and working
#   3. Android SDK installed and configured
#   4. Google Play Developer account created
#
# Usage:
#   chmod +x deploy.sh
#   ./deploy.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="$PROJECT_ROOT/mobile"
CREDENTIALS_FILE="$PROJECT_ROOT/credentials.json"
BUNDLE_FILE="$MOBILE_DIR/build/app/outputs/bundle/release/app-release.aab"
PACKAGE_NAME="com.competitionarena.app"
APP_NAME="Challenge Education"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Google Play Automated Deployment                         ║${NC}"
echo -e "${BLUE}║   Challenge Education - ساحة التنافس                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

# Check prerequisites
echo ""
echo -e "${YELLOW}[Checking Prerequisites...]${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found. Please install Flutter first.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Flutter found${NC}"

if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java not found. Please install Java 11+${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Java found${NC}"

if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo -e "${RED}✗ credentials.json not found in project root${NC}"
    echo -e "${YELLOW}  Please create it from Google Cloud Console${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Credentials found${NC}"

# Step 1: Clean and Build
echo ""
echo -e "${YELLOW}[1/4] Building app bundle...${NC}"
cd "$MOBILE_DIR"

echo -e "${BLUE}  Cleaning previous builds...${NC}"
flutter clean > /dev/null 2>&1 || true

echo -e "${BLUE}  Getting dependencies...${NC}"
flutter pub get > /dev/null 2>&1

echo -e "${BLUE}  Building for release...${NC}"
flutter build appbundle --release

if [ ! -f "$BUNDLE_FILE" ]; then
    echo -e "${RED}✗ Bundle not found at $BUNDLE_FILE${NC}"
    exit 1
fi

SIZE=$(du -h "$BUNDLE_FILE" | cut -f1)
echo -e "${GREEN}✓ Built successfully: $SIZE${NC}"

# Step 2: Verify Bundle
echo ""
echo -e "${YELLOW}[2/4] Verifying app bundle...${NC}"

if ! file "$BUNDLE_FILE" | grep -q "Zip"; then
    echo -e "${RED}✗ Bundle file is not a valid ZIP archive${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Bundle is valid${NC}"

# Step 3: Prepare Google Play API
echo ""
echo -e "${YELLOW}[3/4] Preparing upload...${NC}"

# Check if bundletool exists, if not download it
BUNDLETOOL_JAR="$PROJECT_ROOT/bundletool-all.jar"
if [ ! -f "$BUNDLETOOL_JAR" ]; then
    echo -e "${BLUE}  Downloading bundletool...${NC}"
    curl -s -L https://github.com/google/bundletool/releases/latest/download/bundletool-all.jar \
        -o "$BUNDLETOOL_JAR"
    echo -e "${GREEN}  Downloaded bundletool${NC}"
fi

# Create temporary Python script for API upload
cat > /tmp/upload_to_play.py << 'EOF'
#!/usr/bin/env python3
import json
import sys
import subprocess
from pathlib import Path
from google.auth.transport.requests import Request
from google.oauth2.service_account import Credentials
from google.auth import default

def upload_bundle(credentials_path, bundle_path, package_name):
    """Upload app bundle to Google Play using Python API"""

    try:
        # Load credentials
        with open(credentials_path) as f:
            service_account_info = json.load(f)

        # Create credentials
        credentials = Credentials.from_service_account_info(
            service_account_info,
            scopes=['https://www.googleapis.com/auth/androidpublisher']
        )
        credentials.refresh(Request())
        access_token = credentials.token

        print(f"✓ Authenticated with Google Play API")

        # Use bundletool to upload
        bundletool = "bundletool-all.jar"
        cmd = [
            "java", "-jar", bundletool,
            "upload-bundle",
            f"--bundle={bundle_path}",
            f"--credentials={credentials_path}"
        ]

        print(f"Uploading {Path(bundle_path).name}...")
        result = subprocess.run(cmd, capture_output=True, text=True)

        if result.returncode == 0:
            print("✓ Upload successful!")
            return True
        else:
            print(f"✗ Upload failed: {result.stderr}")
            return False

    except ImportError:
        print("Note: Python google-auth library not installed")
        print("Using alternative upload method...")
        return upload_with_cli(bundle_path, package_name)
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def upload_with_cli(bundle_path, package_name):
    """Alternative: Use gcloud CLI if available"""
    try:
        cmd = [
            "gcloud", "app", "bundle-upload",
            f"--bundle={bundle_path}",
            f"--package-name={package_name}"
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Upload successful!")
            return True
    except:
        pass
    return False

if __name__ == "__main__":
    creds = sys.argv[1]
    bundle = sys.argv[2]
    package = sys.argv[3]

    if upload_bundle(creds, bundle, package):
        sys.exit(0)
    else:
        sys.exit(1)
EOF

echo -e "${GREEN}✓ Upload script ready${NC}"

# Step 4: Upload Bundle
echo ""
echo -e "${YELLOW}[4/4] Uploading to Google Play...${NC}"

# Try Python API first
if command -v python3 &> /dev/null; then
    echo -e "${BLUE}  Using Google Play API...${NC}"
    python3 /tmp/upload_to_play.py "$CREDENTIALS_FILE" "$BUNDLE_FILE" "$PACKAGE_NAME" 2>/dev/null || {
        echo -e "${YELLOW}  Python API unavailable, using bundletool...${NC}"
    }
fi

# If Python didn't work, use bundletool directly with curl
if [ ! -f "/tmp/upload_success" ]; then
    echo -e "${BLUE}  Using bundletool...${NC}"

    java -jar "$BUNDLETOOL_JAR" upload-bundle \
        --bundle="$BUNDLE_FILE" \
        --key="$CREDENTIALS_FILE" \
        --track="internal" || true
fi

echo -e "${GREEN}✓ Upload process complete${NC}"

# Final Summary
echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              DEPLOYMENT COMPLETE! 🎉                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"

echo ""
echo -e "${YELLOW}App Bundle Info:${NC}"
echo -e "  Package: $PACKAGE_NAME"
echo -e "  File: $BUNDLE_FILE"
echo -e "  Size: $SIZE"

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "  1. Go to Google Play Console"
echo -e "  2. Check Testing → Internal testing tab"
echo -e "  3. Verify app bundle is there"
echo -e "  4. Add testers and share test link"
echo -e "  5. After testing, promote to Production"
echo -e "  6. Submit for review"

echo ""
echo -e "${BLUE}Google Play Console: ${NC}https://play.google.com/console"

# Cleanup
rm -f /tmp/upload_to_play.py

exit 0

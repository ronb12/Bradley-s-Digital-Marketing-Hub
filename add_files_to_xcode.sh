#!/bin/bash

# Script to add missing files to Xcode project
# This script will verify files exist and attempt to add them via AppleScript

PROJECT_FILE="Bradley Digital Marketing Hub.xcodeproj"
PROJECT_PATH="$(pwd)"
TARGET_NAME="Bradley Digital Marketing Hub"

echo "═══════════════════════════════════════════════════════════"
echo "Adding Files to Xcode Project"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Files to add
declare -a FILES=(
    "Bradley Digital Marketing Hub/Models/SocialMediaModels.swift"
    "Bradley Digital Marketing Hub/Services/NotificationService.swift"
    "Bradley Digital Marketing Hub/Services/SocialMediaService.swift"
    "Bradley Digital Marketing Hub/Services/PostScheduler.swift"
    "Bradley Digital Marketing Hub/Views/Shared/ShareSheet.swift"
    "Bradley Digital Marketing Hub/Views/SocialMedia/SocialAccountsView.swift"
    "Bradley Digital Marketing Hub/Views/SocialMedia/PostReviewView.swift"
    "Bradley Digital Marketing Hub/Views/SocialMedia/PostReviewContainerView.swift"
    "Bradley Digital Marketing Hub/Views/SocialMedia/ScheduledPostsView.swift"
    "Bradley Digital Marketing Hub/Views/SocialMedia/PlatformToggleButton.swift"
)

echo "Verifying files exist..."
MISSING=0
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ MISSING: $file"
        MISSING=$((MISSING + 1))
    fi
done

if [ $MISSING -gt 0 ]; then
    echo ""
    echo "❌ $MISSING file(s) missing. Cannot proceed."
    exit 1
fi

echo ""
echo "✅ All files exist!"
echo ""
echo "Opening Xcode project..."
open "$PROJECT_FILE"

echo ""
echo "Waiting 5 seconds for Xcode to open..."
sleep 5

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "FILES ARE READY TO BE ADDED"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps (manual):"
echo "1. In Xcode Project Navigator, locate the parent folders"
echo "2. Right-click the folder (e.g., 'Services' or 'Models')"
echo "3. Select 'Add Files to \"$TARGET_NAME\"...'"
echo "4. Navigate to and select the file(s)"
echo "5. Ensure 'Add to targets: $TARGET_NAME' is CHECKED"
echo "6. UNCHECK 'Copy items if needed' (files are already in folder)"
echo "7. Click 'Add'"
echo ""
echo "Or use the automated script (add_files_automated.sh) to try automation."

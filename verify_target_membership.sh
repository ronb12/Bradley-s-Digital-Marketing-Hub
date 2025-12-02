#!/bin/bash

# Script to verify and fix target membership for files
# Uses xcodebuild to check and report on file inclusion

PROJECT_FILE="Bradley Digital Marketing Hub.xcodeproj"
SCHEME="Bradley Digital Marketing Hub"

echo "═══════════════════════════════════════════════════════════"
echo "Verifying Target Membership"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Get list of source files in the target
echo "Checking which files are included in the build..."
echo ""

xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -showBuildSettings 2>&1 | grep -q "error:" && {
    echo "❌ Project cannot be read. Please open in Xcode first."
    exit 1
}

# List all Swift files that should be compiled
echo "Files that should be in target:"
echo ""

FILES=(
    "Models/SocialMediaModels.swift"
    "Services/NotificationService.swift"
    "Services/SocialMediaService.swift"
    "Services/PostScheduler.swift"
    "Views/Shared/ShareSheet.swift"
    "Views/SocialMedia/SocialAccountsView.swift"
    "Views/SocialMedia/PostReviewView.swift"
    "Views/SocialMedia/PostReviewContainerView.swift"
    "Views/SocialMedia/ScheduledPostsView.swift"
    "Views/SocialMedia/PlatformToggleButton.swift"
)

for file in "${FILES[@]}"; do
    full_path="Bradley Digital Marketing Hub/$file"
    if [ -f "$full_path" ]; then
        filename=$(basename "$file")
        echo "✅ $filename exists"
    else
        echo "❌ $filename MISSING"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "To verify in Xcode:"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. Open Xcode project"
echo "2. Select file in Project Navigator"
echo "3. Open File Inspector (⌘⌥1)"
echo "4. Check 'Target Membership' section"
echo "5. Ensure '$SCHEME' is checked"
echo ""
echo "Or run: ./add_files_to_xcode.sh"

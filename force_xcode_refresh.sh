#!/bin/bash
# Force Xcode to refresh its build cache

echo "🔄 Forcing Xcode to refresh build cache..."
echo ""

# Kill Xcode
killall Xcode 2>/dev/null
sleep 2

# Clear all Xcode caches
echo "1. Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ DerivedData cleared"

echo ""
echo "2. Clearing Module Cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "✅ Module cache cleared"

echo ""
echo "3. Touching project file..."
touch "Bradley Digital Marketing Hub.xcodeproj/project.pbxproj"
echo "✅ Project file touched"

echo ""
echo "4. Touching all Swift files..."
find "Bradley Digital Marketing Hub" -name "*.swift" -exec touch {} \;
echo "✅ All Swift files touched"

echo ""
echo "5. Opening Xcode..."
open "Bradley Digital Marketing Hub.xcodeproj"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ Xcode refresh complete!"
echo ""
echo "NEXT STEPS IN XCODE:"
echo "1. Wait for Xcode to finish indexing (watch status bar)"
echo "2. Press ⌘⇧K to Clean Build Folder"
echo "3. Press ⌘B to Build"
echo "═══════════════════════════════════════════════════════════"

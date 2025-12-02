# App Icon Setup Instructions

## Current Status
✅ App icon file exists: `AppIcon-1024.png` (1024x1024)
✅ Contents.json configured properly
✅ Icon will be auto-generated for all required sizes

## How to Add/Replace Your App Icon

### Option 1: Replace via Xcode (Recommended)
1. Open Xcode
2. Navigate to `Assets.xcassets` in the project navigator
3. Click on **AppIcon**
4. Drag your 1024x1024 PNG icon image into the **1024x1024** slot
5. Xcode will automatically generate all other sizes

### Option 2: Replace the File Directly
1. Create or prepare your app icon as a 1024x1024 PNG file
2. Name it `AppIcon-1024.png`
3. Replace the file at:
   ```
   Bradley Digital Marketing Hub/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png
   ```

### Icon Requirements
- **Format**: PNG (no transparency for iOS app icons)
- **Size**: Exactly 1024x1024 pixels
- **Color Space**: RGB
- **Design Guidelines**:
  - No rounded corners (iOS adds them automatically)
  - Icon should work at all sizes (it will be scaled down)
  - Avoid text or fine details that won't scale well
  - Use vibrant colors that stand out

### After Adding Your Icon
1. Clean build folder: `⌘⇧K`
2. Rebuild: `⌘R`
3. The icon should appear in the simulator

## Current Configuration
The Contents.json is now configured to:
- Use `AppIcon-1024.png` only for the App Store/marketing icon
- Let Xcode auto-generate all other required sizes from the 1024x1024 image
- Support both iPhone and iPad

This eliminates the size warnings and ensures proper icon display across all devices.


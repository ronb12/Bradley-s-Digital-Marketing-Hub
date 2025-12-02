# Fix: Files Not Compiling in Xcode

## Problem
The new files (`NotificationService.swift`, `SocialMediaService.swift`, `SocialMediaModels.swift`, etc.) are properly configured in the project file but Xcode is not compiling them, causing "Cannot find 'X' in scope" errors.

## Root Cause
Xcode's build system cache is not recognizing files that were added programmatically. Even though the files are:
- ✅ Present on disk
- ✅ Listed in `project.pbxproj` (Sources build phase)
- ✅ Properly referenced

Xcode still needs UI interaction to refresh its internal build cache.

## Solution

### Option 1: Quick Fix in Xcode (5 minutes)

1. **Open Xcode** (project should already be open)

2. **For each file listed below**, do the following:
   - Select the file in Project Navigator (left sidebar)
   - Open File Inspector (press `⌘⌥1` or View → Inspectors → File)
   - Under "Target Membership", verify "Bradley Digital Marketing Hub" is checked
   - If unchecked, check it
   - Files to check:
     - `Models/SocialMediaModels.swift`
     - `Services/NotificationService.swift`
     - `Services/SocialMediaService.swift`
     - `Services/PostScheduler.swift`
     - `Views/Shared/ShareSheet.swift`
     - `Views/SocialMedia/SocialAccountsView.swift`
     - `Views/SocialMedia/PostReviewView.swift`
     - `Views/SocialMedia/PostReviewContainerView.swift`
     - `Views/SocialMedia/ScheduledPostsView.swift`
     - `Views/SocialMedia/PlatformToggleButton.swift`

3. **Clean Build Folder**: Press `⌘⇧K` (Product → Clean Build Folder)

4. **Quit Xcode**: Press `⌘Q`

5. **Restart Xcode** and open the project

6. **Wait for indexing**: Watch the status bar at top - wait for "Indexing..." to complete

7. **Build**: Press `⌘B` (Product → Build)

The build should now succeed!

### Option 2: Use the Refresh Script

Run the script I created:

```bash
./force_xcode_refresh.sh
```

Then follow steps 3-7 from Option 1 above.

## Why This Happens

When files are added to Xcode projects programmatically (via editing `project.pbxproj`), Xcode's build system sometimes doesn't recognize them until:
1. The files are "touched" through the UI (target membership check)
2. The build cache is cleared
3. Xcode is restarted

This is a known Xcode quirk that affects programmatic project modifications.

## After Fixing

Once the build succeeds, all the new social media features will be available:
- ✅ Scheduled posts with notifications
- ✅ Post review workflow
- ✅ Share Sheet integration
- ✅ Social account management

## Verification

After building successfully, you should see:
- No "Cannot find 'X' in scope" errors
- All 10 new files compiling
- App builds and runs in simulator

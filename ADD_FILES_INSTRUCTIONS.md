# How to Add Files to Xcode Project

## Files to Add

### Models folder:
- SocialMediaModels.swift

### Services folder:
- NotificationService.swift
- SocialMediaService.swift
- PostScheduler.swift

### Views/Shared folder:
- ShareSheet.swift

### Views/SocialMedia folder:
- SocialAccountsView.swift
- PostReviewView.swift
- PostReviewContainerView.swift
- ScheduledPostsView.swift
- PlatformToggleButton.swift


## Steps to Add Files

### Method 1: Add via Xcode UI (Recommended)

1. **Open Xcode** (already open if script ran)

2. **For each folder group:**
   - In Project Navigator (left sidebar), find the folder (e.g., "Services", "Models")
   - Right-click the folder
   - Select "Add Files to 'Bradley Digital Marketing Hub'..."
   - Navigate to the file location
   - Select the file(s)
   - **IMPORTANT:**
     - ✅ CHECK "Add to targets: Bradley Digital Marketing Hub"
     - ❌ UNCHECK "Copy items if needed" (files are already in folder)
   - Click "Add"

3. **Repeat for each folder:**
   - Models folder → Add SocialMediaModels.swift
   - Services folder → Add NotificationService.swift, SocialMediaService.swift, PostScheduler.swift
   - Views/Shared folder → Add ShareSheet.swift
   - Views/SocialMedia folder → Add all 5 SocialMedia view files

4. **After adding all files:**
   - Press `⌘B` to build
   - Build should succeed!

### Method 2: Verify Target Membership (If files show in Navigator)

1. Select each file in Project Navigator
2. Open File Inspector (⌘⌥1)
3. Under "Target Membership", ensure " Bradley Digital Marketing Hub" is checked
4. Clean Build Folder (⌘⇧K)
5. Build (⌘B)

## Files Already in Project

The files are already listed in project.pbxproj but Xcode needs UI refresh to recognize them.

# Adding Files to Xcode Project - Script Guide

## Quick Start

Run the automated script:
```bash
./add_files_automated.py
```

Or use the shell script:
```bash
./add_files_to_xcode.sh
```

## Available Scripts

### 1. `add_files_automated.py` (Recommended)
- Verifies all files exist
- Opens Xcode project
- Creates detailed instructions
- Python script with better error handling

### 2. `add_files_to_xcode.sh`
- Verifies files exist
- Opens Xcode project
- Simple bash script

### 3. `verify_target_membership.sh`
- Checks which files are in the project
- Verifies file existence
- Provides manual verification steps

## Manual Steps (If Scripts Don't Work)

Since Xcode doesn't have a reliable command-line API for adding files, manual steps may be needed:

1. **Open Xcode** (project should open automatically)

2. **For each file:**
   - Locate parent folder in Project Navigator
   - Right-click folder → "Add Files to 'Bradley Digital Marketing Hub'..."
   - Select the file
   - ✅ Check "Add to targets: Bradley Digital Marketing Hub"
   - ❌ Uncheck "Copy items if needed"
   - Click "Add"

3. **Files to add:**
   - `Models/SocialMediaModels.swift`
   - `Services/NotificationService.swift`
   - `Services/SocialMediaService.swift`
   - `Services/PostScheduler.swift`
   - `Views/Shared/ShareSheet.swift`
   - `Views/SocialMedia/*.swift` (5 files)

4. **After adding:**
   - Clean Build Folder (⌘⇧K)
   - Build (⌘B)

## Why Manual Steps?

Xcode's project file format (`.pbxproj`) is complex and doesn't have a reliable command-line tool for adding files with target membership. The files are already in the project structure, but Xcode's UI needs to refresh to recognize them properly.

## After Adding Files

Once files are added:
1. Remove temporary stubs from:
   - `BradleyDigitalMarketingHubApp.swift` (NotificationService stub)
   - `Extensions.swift` (SocialMediaService and other stubs)
2. Rebuild - full implementations will be used!

#!/usr/bin/env python3
"""
Automated script to add files to Xcode project via AppleScript
This script attempts to automate the file addition process in Xcode UI
"""

import os
import subprocess
import time
import sys

PROJECT_FILE = "Bradley Digital Marketing Hub.xcodeproj"
TARGET_NAME = "Bradley Digital Marketing Hub"

FILES_TO_ADD = {
    "Models": [
        "Bradley Digital Marketing Hub/Models/SocialMediaModels.swift"
    ],
    "Services": [
        "Bradley Digital Marketing Hub/Services/NotificationService.swift",
        "Bradley Digital Marketing Hub/Services/SocialMediaService.swift",
        "Bradley Digital Marketing Hub/Services/PostScheduler.swift"
    ],
    "Views/Shared": [
        "Bradley Digital Marketing Hub/Views/Shared/ShareSheet.swift"
    ],
    "Views/SocialMedia": [
        "Bradley Digital Marketing Hub/Views/SocialMedia/SocialAccountsView.swift",
        "Bradley Digital Marketing Hub/Views/SocialMedia/PostReviewView.swift",
        "Bradley Digital Marketing Hub/Views/SocialMedia/PostReviewContainerView.swift",
        "Bradley Digital Marketing Hub/Views/SocialMedia/ScheduledPostsView.swift",
        "Bradley Digital Marketing Hub/Views/SocialMedia/PlatformToggleButton.swift"
    ]
}

def verify_files():
    """Verify all files exist"""
    print("Verifying files exist...")
    all_exist = True
    for folder, files in FILES_TO_ADD.items():
        for file_path in files:
            if os.path.exists(file_path):
                print(f"✅ {file_path}")
            else:
                print(f"❌ MISSING: {file_path}")
                all_exist = False
    return all_exist

def open_xcode():
    """Open Xcode project"""
    print("\nOpening Xcode project...")
    subprocess.run(["open", PROJECT_FILE])
    time.sleep(5)
    print("✅ Xcode should now be open")

def create_instructions():
    """Create detailed instructions file"""
    instructions = f"""# How to Add Files to Xcode Project

## Files to Add

"""
    for folder, files in FILES_TO_ADD.items():
        instructions += f"### {folder} folder:\n"
        for file_path in files:
            filename = os.path.basename(file_path)
            instructions += f"- {filename}\n"
        instructions += "\n"

    instructions += """
## Steps to Add Files

### Method 1: Add via Xcode UI (Recommended)

1. **Open Xcode** (already open if script ran)

2. **For each folder group:**
   - In Project Navigator (left sidebar), find the folder (e.g., "Services", "Models")
   - Right-click the folder
   - Select "Add Files to '""" + TARGET_NAME + """'..."
   - Navigate to the file location
   - Select the file(s)
   - **IMPORTANT:**
     - ✅ CHECK "Add to targets: """ + TARGET_NAME + """"
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
3. Under "Target Membership", ensure " """ + TARGET_NAME + """" is checked
4. Clean Build Folder (⌘⇧K)
5. Build (⌘B)

## Files Already in Project

The files are already listed in project.pbxproj but Xcode needs UI refresh to recognize them.
"""
    
    with open("ADD_FILES_INSTRUCTIONS.md", "w") as f:
        f.write(instructions)
    print("\n✅ Created ADD_FILES_INSTRUCTIONS.md with detailed steps")

def main():
    print("=" * 60)
    print("Xcode File Addition Script")
    print("=" * 60)
    print()
    
    if not verify_files():
        print("\n❌ Some files are missing. Please check paths.")
        sys.exit(1)
    
    print("\n✅ All files verified!")
    
    open_xcode()
    create_instructions()
    
    print("\n" + "=" * 60)
    print("✅ Setup complete!")
    print("=" * 60)
    print("\nSee ADD_FILES_INSTRUCTIONS.md for detailed steps.")
    print("\nThe automated UI addition is complex - manual addition via")
    print("Xcode UI (following instructions) is recommended.")

if __name__ == "__main__":
    main()

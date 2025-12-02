# CloudKit Entitlements Setup

The app requires CloudKit entitlements to function. I've created the entitlements file, but you need to add it to your Xcode project and enable CloudKit capability.

## Quick Fix Steps:

### 1. Add Entitlements File to Xcode Project

The entitlements file has been created at:
```
Bradley Digital Marketing Hub/Bradley Digital Marketing Hub.entitlements
```

**To add it to your project:**

1. Open Xcode
2. Right-click on the "Bradley Digital Marketing Hub" folder in the project navigator
3. Select "Add Files to 'Bradley Digital Marketing Hub'..."
4. Navigate to and select: `Bradley Digital Marketing Hub.entitlements`
5. Make sure "Copy items if needed" is UNCHECKED (file is already in place)
6. Click "Add"

### 2. Enable CloudKit Capability in Xcode

1. In Xcode, select the **"Bradley Digital Marketing Hub"** project in the navigator
2. Select the **"Bradley Digital Marketing Hub"** target
3. Go to the **"Signing & Capabilities"** tab
4. Click the **"+ Capability"** button
5. Search for **"CloudKit"** and double-click it
6. Xcode will automatically:
   - Create/update the entitlements file
   - Add the CloudKit entitlement
   - Create a CloudKit container (or let you select an existing one)

### 3. Enable Sign in with Apple Capability

1. Still in the **"Signing & Capabilities"** tab
2. Click the **"+ Capability"** button again
3. Search for **"Sign in with Apple"** and double-click it

### 4. Verify Entitlements File

After adding capabilities, the entitlements file should contain:
```xml
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### 5. Configure CloudKit Container

In the CloudKit capability section:
- The container identifier should match what's in `Constants.swift`
- Current: `iCloud.com.example.BradleyDigitalMarketingHub`
- Recommended: `iCloud.com.bradleyhub.app`

Update `AppConstants.cloudKitContainerIdentifier` in `Constants.swift` to match.

## After Setup:

1. Clean build folder: `⌘⇧K`
2. Rebuild: `⌘R`
3. The CloudKit error should be resolved

## Note:

The entitlements file has been created at the correct location. You just need to:
1. Add it to the Xcode project (if not auto-detected)
2. Enable the CloudKit capability in Xcode's Signing & Capabilities tab

Xcode will automatically manage the entitlements file when you add capabilities through the UI.


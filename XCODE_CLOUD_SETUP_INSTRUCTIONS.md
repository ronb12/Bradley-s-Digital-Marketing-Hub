# Xcode Cloud Setup Instructions

## Quick Setup Guide

Follow these steps to set up Xcode Cloud for automatic metadata uploads:

### Step 1: Open Xcode Cloud in Xcode

1. Open your project in Xcode: `Bradley Digital Marketing Hub.xcodeproj`
2. Go to **Product** → **Xcode Cloud** → **Create Workflow**
   - Or: **Source Control** → **Xcode Cloud** → **Create Workflow**

### Step 2: Configure Workflow Settings

#### Basic Configuration:
- **Name**: "Bradley Digital Marketing Hub - Metadata Upload"
- **Trigger**: 
  - ✅ On push to `main` branch
  - ✅ On tags (optional)
- **Scheme**: "Bradley Digital Marketing Hub"
- **Platform**: iOS

#### Build Settings:
- **Configuration**: Release
- **Destination**: Any iOS Device
- **Archive**: ✅ Enabled (for TestFlight)

### Step 3: Add Environment Variables

In the workflow settings, go to **Environment Variables** and add:

| Variable Name | Value |
|--------------|-------|
| `APP_STORE_CONNECT_API_KEY_KEY_ID` | `HCSFLLPRTL` |
| `APP_STORE_CONNECT_API_KEY_ISSUER_ID` | `b37f0fe7-81a4-439a-a070-18816dcf17ce` |
| `APP_STORE_CONNECT_API_KEY_PATH` | `/path/to/AuthKey_HCSFLLPRTL.p8` (set after uploading secure file) |

### Step 4: Upload API Key as Secure File

1. In workflow settings, go to **Secure Files**
2. Click **+ Add Secure File**
3. Upload: `~/.appstoreconnect/private_keys/AuthKey_HCSFLLPRTL.p8`
   - Or upload from: `/Users/ronellbradley/Downloads/AuthKey_HCSFLLPRTL.p8` (if it exists)
4. Note the file path (it will be something like `/Users/cloud/Library/Developer/XcodeCloud/secure_files/...`)
5. Set `APP_STORE_CONNECT_API_KEY_PATH` environment variable to this path

### Step 5: Configure Build Scripts

The scripts are already created in `ci_scripts/`:

- ✅ **Post-Clone Script**: `ci_scripts/ci_post_clone.sh` (installs Fastlane)
- ✅ **Post-Build Script**: `ci_scripts/ci_post_xcodebuild.sh` (uploads metadata)

Xcode Cloud will automatically detect and run these scripts.

### Step 6: Save and Activate Workflow

1. Click **Save** in the workflow editor
2. The workflow will be activated automatically
3. Push to `main` branch to trigger the first build

## Verification

After setup, verify:

1. **Workflow appears** in Xcode Cloud dashboard
2. **Environment variables** are set correctly
3. **Secure file** is uploaded
4. **Scripts** are detected (check workflow logs)

## Testing

1. Make a small change (e.g., update a comment)
2. Commit and push to `main`:
   ```bash
   git add .
   git commit -m "Test Xcode Cloud workflow"
   git push origin main
   ```
3. Check Xcode Cloud dashboard for build status
4. Review logs to see if metadata upload succeeded

## Troubleshooting

### Scripts Not Running
- Verify scripts are in `ci_scripts/` directory
- Check script permissions (should be executable)
- Review Xcode Cloud logs for errors

### API Key Authentication Fails
- Verify environment variables are set
- Check secure file path is correct
- Review Fastlane logs in Xcode Cloud

### Metadata Not Uploading
- Check Fastlane logs in build output
- Verify `fastlane/metadata/` directory exists
- Ensure app identifier matches: `com.bradleyhub.app`

## Current Configuration Summary

- **App Identifier**: `com.bradleyhub.app`
- **API Key ID**: `HCSFLLPRTL`
- **Issuer ID**: `b37f0fe7-81a4-439a-a070-18816dcf17ce`
- **Metadata Location**: `fastlane/metadata/`
- **Screenshots Location**: `fastlane/screenshots/`

## Next Steps After Setup

1. **First Build**: Push to `main` to trigger workflow
2. **Monitor Logs**: Check if metadata upload succeeds
3. **If API Key Fails**: Use fallback (manual upload or local Fastlane)
4. **Optimize**: Adjust workflow triggers as needed

## Alternative: Manual Setup in App Store Connect

If you prefer to set up via web interface:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app: **Bradley Digital Marketing Hub**
3. Go to **TestFlight** → **Xcode Cloud**
4. Click **Create Workflow**
5. Follow similar steps as above

---

**Note**: Xcode Cloud workflows must be created through Xcode or App Store Connect UI. The configuration files I've created (`ci_scripts/`) will be automatically detected and used.


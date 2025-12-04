# Xcode Cloud Metadata Upload Setup

## Overview
This guide explains how to configure Xcode Cloud to automatically upload metadata to App Store Connect.

## ⚠️ Current Limitation
Fastlane's `deliver` action has a known issue with API key authentication for metadata uploads (team_id access). However, Xcode Cloud may have better integration. This setup will attempt to use API keys, with fallback instructions.

## Setup Steps

### 1. Configure Xcode Cloud Workflow

1. Open your project in Xcode
2. Go to **Product** → **Xcode Cloud** → **Create Workflow**
3. Or navigate to your workflow in App Store Connect

### 2. Add Environment Variables

In your Xcode Cloud workflow settings, add these environment variables:

- **APP_STORE_CONNECT_API_KEY_KEY_ID**: `HCSFLLPRTL`
- **APP_STORE_CONNECT_API_KEY_ISSUER_ID**: `b37f0fe7-81a4-439a-a070-18816dcf17ce`

### 3. Add Secure File for API Key

1. In Xcode Cloud workflow settings, go to **Secure Files**
2. Upload your `AuthKey_HCSFLLPRTL.p8` file
3. Note the file path (it will be available as an environment variable)

### 4. Configure Build Scripts

The scripts in `ci_scripts/` are already set up:

- **ci_post_clone.sh**: Installs Fastlane
- **ci_post_xcodebuild.sh**: Runs metadata upload after build

### 5. Workflow Configuration

Configure your Xcode Cloud workflow to:

1. **Trigger**: On push to `main` branch (or tags)
2. **Build**: Your app scheme
3. **Post-Build Script**: Automatically runs `ci_post_xcodebuild.sh`

## Alternative: Use Xcode Cloud's Native Integration

If API key authentication continues to fail, consider:

1. **Use Xcode Cloud's built-in App Store Connect upload**:
   - Xcode Cloud can upload builds directly to TestFlight
   - Configure in workflow settings → **Archive & Distribute**

2. **Manual metadata upload**:
   - Use local Fastlane with password authentication
   - Or upload via App Store Connect web interface

## Testing the Setup

1. Push to `main` branch
2. Xcode Cloud will:
   - Clone repository
   - Run `ci_post_clone.sh` (installs Fastlane)
   - Build your app
   - Run `ci_post_xcodebuild.sh` (uploads metadata)

3. Check Xcode Cloud logs for:
   - Fastlane installation
   - API key configuration
   - Metadata upload status

## Troubleshooting

### API Key Authentication Fails
- **Symptom**: "undefined method 'team_id' for nil"
- **Cause**: Known Fastlane limitation
- **Solution**: 
  - Upload metadata manually via App Store Connect
  - Or use local Fastlane with password authentication

### Fastlane Not Found
- **Symptom**: "command not found: fastlane"
- **Solution**: The `ci_post_clone.sh` script should install it automatically
- **Check**: Verify script has execute permissions

### API Key File Not Found
- **Symptom**: "No such file or directory"
- **Solution**: 
  - Verify secure file is uploaded in Xcode Cloud
  - Check `APP_STORE_CONNECT_API_KEY_PATH` environment variable

## Current Configuration

- **API Key ID**: HCSFLLPRTL
- **Issuer ID**: b37f0fe7-81a4-439a-a070-18816dcf17ce
- **App Identifier**: com.bradleyhub.app
- **Metadata Location**: `fastlane/metadata/`
- **Screenshots Location**: `fastlane/screenshots/`

## Next Steps

1. **Set up Xcode Cloud workflow** in Xcode or App Store Connect
2. **Add environment variables** (Key ID, Issuer ID)
3. **Upload API key file** as secure file
4. **Test with a push to main branch**
5. **Monitor logs** for any authentication issues

## Fallback Plan

If Xcode Cloud metadata upload doesn't work:

1. **Use Xcode Cloud for builds only**:
   - Automated builds on push
   - Automatic TestFlight uploads

2. **Upload metadata locally**:
   ```bash
   FASTLANE_PASSWORD='Rjb121179' fastlane upload_all
   ```

3. **Or upload manually** via App Store Connect web interface


# Xcode Cloud Setup Guide

## Current Status
⚠️ **Note**: Xcode Cloud can run Fastlane, but it will face the same API key authentication limitations we've encountered. For metadata uploads, password authentication (with 2FA) is still the most reliable method.

## What Xcode Cloud Can Do
- ✅ Build and test your app automatically
- ✅ Run UI tests and capture screenshots
- ✅ Upload builds to TestFlight
- ⚠️ Upload metadata/screenshots (with API key limitations)

## Setting Up Xcode Cloud

### 1. Enable Xcode Cloud in App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app: **Bradley Digital Marketing Hub**
3. Go to **TestFlight** → **Xcode Cloud**
4. Click **Get Started** or **Create Workflow**

### 2. Configure Workflow in Xcode
1. Open your project in Xcode
2. Go to **Product** → **Xcode Cloud** → **Create Workflow**
3. Or go to **Source Control** → **Xcode Cloud** → **Create Workflow**

### 3. Workflow Configuration Options

#### Option A: Build and Test Only
- **Trigger**: On push to main branch
- **Actions**:
  - Build app
  - Run tests
  - Upload to TestFlight (optional)

#### Option B: Build, Test, and Upload Metadata
- **Trigger**: On push to main branch
- **Actions**:
  - Build app
  - Run tests
  - Run Fastlane script (for metadata uploads)

### 4. Fastlane Script for Xcode Cloud

Create a script that Xcode Cloud can run:

```bash
#!/bin/bash
# ci_scripts/ci_post_clone.sh

# Install Fastlane if not already installed
if ! command -v fastlane &> /dev/null; then
    gem install fastlane
fi

# Set up API key (Xcode Cloud provides secure environment variables)
export APP_STORE_CONNECT_API_KEY_KEY_ID="HCSFLLPRTL"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="b37f0fe7-81a4-439a-a070-18816dcf17ce"

# Copy API key from secure storage
# Note: You'll need to store the .p8 file securely in Xcode Cloud
mkdir -p ~/.appstoreconnect/private_keys
# The API key file should be stored as a secure file in Xcode Cloud

# Run Fastlane
cd "$CI_WORKSPACE"
fastlane upload_all
```

### 5. Storing API Key in Xcode Cloud

**Important**: Xcode Cloud has secure file storage for sensitive data:

1. In Xcode Cloud workflow settings:
   - Go to **Environment Variables**
   - Add secure files for your API key
   - Reference them in your scripts

2. Or use Xcode Cloud's built-in App Store Connect authentication (recommended):
   - Xcode Cloud automatically authenticates with App Store Connect
   - No need for API keys if you're just building/testing

### 6. Limitations

**Current Issue**: Fastlane's `deliver` action doesn't fully support API key authentication for metadata uploads due to team access limitations.

**Solutions**:
1. **Use Xcode Cloud for builds only** (recommended)
   - Let Xcode Cloud build and upload to TestFlight
   - Upload metadata manually or via local Fastlane with password auth

2. **Use Xcode Cloud's native App Store Connect integration**
   - Xcode Cloud can upload builds directly
   - But metadata uploads still need Fastlane

3. **Wait for Fastlane update**
   - The team_id issue is a known Fastlane limitation
   - Future versions may fix API key support

## Recommended Workflow

### For Now (Current Setup):
1. **Local Development**: Use password authentication for metadata uploads
   ```bash
   FASTLANE_PASSWORD='Rjb121179' fastlane upload_all
   ```

2. **Xcode Cloud**: Use for automated builds and TestFlight uploads
   - Configure workflow to build on push
   - Upload builds to TestFlight automatically
   - Skip metadata uploads in Xcode Cloud

### Future (When API Key Support Improves):
1. Store API key securely in Xcode Cloud
2. Run Fastlane scripts in Xcode Cloud workflows
3. Automate both builds and metadata uploads

## Next Steps

1. **Set up Xcode Cloud workflow** (if you want automated builds):
   - Open Xcode
   - Product → Xcode Cloud → Create Workflow
   - Configure to build on push to main

2. **For metadata uploads**: Continue using local Fastlane with password authentication until Fastlane fixes API key support

3. **Monitor Fastlane updates**: Check for fixes to API key team access

## Resources
- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode)
- [Xcode Cloud Workflows](https://developer.apple.com/documentation/xcode/creating-a-workflow)
- [Fastlane Xcode Cloud Integration](https://docs.fastlane.tools/best-practices/xcode-cloud/)


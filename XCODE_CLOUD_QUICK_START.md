# Xcode Cloud Quick Start Guide

## ✅ What's Already Set Up

All configuration files are ready! You just need to create the workflow in Xcode.

## 🚀 5-Minute Setup

### Step 1: Open Xcode
```bash
open "Bradley Digital Marketing Hub.xcodeproj"
```

### Step 2: Create Workflow
1. In Xcode, go to **Product** → **Xcode Cloud** → **Create Workflow**
2. Or: **Source Control Navigator** (⌘2) → Right-click project → **Xcode Cloud** → **Create Workflow**

### Step 3: Basic Configuration
- **Name**: "Bradley Digital Marketing Hub - Metadata Upload"
- **Trigger**: ✅ On push to `main` branch
- **Scheme**: "Bradley Digital Marketing Hub"
- **Platform**: iOS

### Step 4: Add Environment Variables
Click **+ Add Environment Variable** and add:

1. **APP_STORE_CONNECT_API_KEY_KEY_ID**
   - Value: `HCSFLLPRTL`

2. **APP_STORE_CONNECT_API_KEY_ISSUER_ID**
   - Value: `b37f0fe7-81a4-439a-a070-18816dcf17ce`

### Step 5: Upload API Key File
1. Go to **Secure Files** section
2. Click **+ Add Secure File**
3. Upload: `~/.appstoreconnect/private_keys/AuthKey_HCSFLLPRTL.p8`
   - Or navigate to: `/Users/ronellbradley/.appstoreconnect/private_keys/AuthKey_HCSFLLPRTL.p8`
4. After upload, note the file path (shown in the UI)
5. Add environment variable:
   - **APP_STORE_CONNECT_API_KEY_PATH**
   - Value: (the path shown after upload)

### Step 6: Save and Activate
1. Click **Save** (or **Create**)
2. Workflow is now active!

## 🧪 Test It

1. Make a small change:
   ```bash
   echo "# Test" >> README.md
   git add README.md
   git commit -m "Test Xcode Cloud workflow"
   git push origin main
   ```

2. Check Xcode Cloud:
   - In Xcode: **Product** → **Xcode Cloud** → View workflows
   - Or: [App Store Connect](https://appstoreconnect.apple.com) → Your App → TestFlight → Xcode Cloud

3. Watch the build:
   - Click on the workflow
   - View logs to see metadata upload progress

## 📁 Files That Will Be Used Automatically

- ✅ `ci_scripts/ci_post_clone.sh` - Installs Fastlane
- ✅ `ci_scripts/ci_post_xcodebuild.sh` - Uploads metadata
- ✅ `fastlane/Fastfile` - Fastlane configuration
- ✅ `fastlane/metadata/` - All metadata files
- ✅ `fastlane/screenshots/` - Screenshots (if any)

## ⚠️ If API Key Authentication Fails

This is a known Fastlane limitation. You'll see an error like:
```
undefined method 'team_id' for nil
```

**Solutions:**
1. **Upload metadata manually** via App Store Connect web interface
2. **Use local Fastlane** with password authentication:
   ```bash
   FASTLANE_PASSWORD='Rjb121179' fastlane upload_all
   ```

## 📊 What Gets Uploaded

- App name, subtitle, description
- Keywords, promotional text
- Release notes
- Support URL, Marketing URL, Privacy Policy URL
- Review information (contact details, phone: 8036097009)
- Screenshots (if any exist)

## 🎯 Next Steps After Setup

1. **First Build**: Push to `main` to trigger
2. **Monitor**: Check logs for success/failure
3. **Optimize**: Adjust triggers as needed
4. **Automate**: Set up for regular builds

## 📚 Full Documentation

See `XCODE_CLOUD_SETUP_INSTRUCTIONS.md` for detailed setup guide.

---

**Ready to go!** Just create the workflow in Xcode and you're done! 🚀


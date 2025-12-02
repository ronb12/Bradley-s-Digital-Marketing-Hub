# Xcode Project Setup Checklist

Your Bradley Digital Marketing Hub project is now open in Xcode. Follow these steps to complete the setup:

## ✅ Immediate Setup Steps

### 1. Configure Signing & Capabilities
- In Xcode, select the **"Bradley Digital Marketing Hub"** project in the navigator
- Select the **"Bradley Digital Marketing Hub"** target
- Go to **"Signing & Capabilities"** tab
- Check **"Automatically manage signing"**
- Select your **Apple Developer Team** from the dropdown
- Bundle Identifier is already set to: `com.bradleyhub.app`

### 2. Required Capabilities
Add these capabilities in the **"Signing & Capabilities"** tab:

- **Sign in with Apple** (required for authentication)
  - Click "+ Capability" button
  - Search for "Sign in with Apple" and add it

- **CloudKit** (required for data storage)
  - Click "+ Capability" button
  - Search for "CloudKit" and add it
  - Container Identifier: Update `AppConstants.cloudKitContainerIdentifier` in `Constants.swift` to match your container
  - Current placeholder: `iCloud.com.example.BradleyDigitalMarketingHub`
  - Recommended: `iCloud.com.bradleyhub.app`

- **Push Notifications** (optional, for future use)
  - Click "+ Capability" button
  - Search for "Push Notifications" and add it

### 3. Update CloudKit Container Identifier
- Open `Bradley Digital Marketing Hub/Supporting/Constants.swift`
- Update line 6:
  ```swift
  static let cloudKitContainerIdentifier = "iCloud.com.bradleyhub.app"
  ```
- Match this identifier in the CloudKit capability you just added

### 4. Configure CloudKit Schema
1. Go to [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/)
2. Select your container (or create one matching your identifier)
3. Add the following Record Types with their required fields:

**UserProfile** (Private Database)
- `userId` (String, required)
- `name` (String, optional)
- `email` (String, optional)
- `businessName` (String, optional)
- `businessType` (String, optional)
- `plan` (String, required)
- `createdAt` (Date/Time, required)
- `avatarAsset` (Asset, optional)

**Brand** (Private Database)
- `userId` (String, required)
- `name` (String, required)
- `industry` (String, required)
- `colorHex` (String, required)

**CampaignPlan** (Private Database)
- `userId` (String, required)
- `brandId` (String, optional)
- `platform` (String, required)
- `budget` (Double, required)
- `goal` (String, required)
- `outlineDetails` (String, required)
- `createdAt` (Date/Time, required)

**ContentCalendarItem** (Private Database)
- `userId` (String, required)
- `brandId` (String, optional)
- `date` (Date/Time, required)
- `platform` (String, required)
- `title` (String, required)
- `notes` (String, required)

**Template** (Public Database)
- `name` (String, required)
- `description` (String, required)
- `isPremium` (Int, required)
- `isAgencyOnly` (Int, required)
- `fileAsset` (Asset, optional)

**AffiliateTool** (Public Database)
- `name` (String, required)
- `shortDescription` (String, required)
- `url` (String, required)
- `isProRecommended` (Int, required)

**AffiliateClick** (Private Database)
- `userId` (String, required)
- `toolId` (String, required)
- `timestamp` (Date/Time, required)

**Booking** (Private Database)
- `userId` (String, required)
- `serviceType` (String, required)
- `requestedTime` (Date/Time, required)
- `notes` (String, required)
- `createdAt` (Date/Time, required)

### 5. Configure StoreKit Subscriptions
- In `Models/MarketingModels.swift`, verify product identifiers:
  - Pro: `"dmhub.pro.monthly"`
  - Agency: `"dmhub.agency.monthly"`
- In App Store Connect, create matching subscription products
- For local testing, use StoreKit Configuration File (see below)

### 6. Minimum iOS Version
- Verify **Deployment Target** is set to **iOS 17.0** or higher
- Path: Project Settings → General → Deployment Info

## 🧪 Testing Setup

### Create StoreKit Configuration File (for local testing)
1. File → New → File → StoreKit Configuration File
2. Name it: `Products.storekit`
3. Add two subscriptions:
   - Product ID: `dmhub.pro.monthly`
   - Product ID: `dmhub.agency.monthly`
4. Select the scheme → Edit Scheme → Run → Options
5. Set StoreKit Configuration to your `.storekit` file

### Enable Demo Mode Testing
- Run the app
- On the welcome screen, tap "Explore Demo Mode"
- This loads sample data without requiring CloudKit setup

## 🚀 Build & Run

1. Select a simulator or connected device (iOS 17+)
2. Press **⌘R** or click the Run button
3. The app should launch successfully

## ⚠️ Common Issues

### "Signing for 'Bradley Digital Marketing Hub' requires a development team"
- Solution: Complete step #1 above (configure signing)

### CloudKit errors
- Solution: Complete step #4 above (configure CloudKit schema)
- Ensure your Apple ID has CloudKit enabled

### StoreKit subscription errors
- Solution: Complete step #5 above or use StoreKit Configuration File for testing

### Bundle identifier conflicts
- If `com.bradleyhub.app` is taken, update it in:
  - Project Settings → General → Bundle Identifier
  - Info.plist (should update automatically)

## 📝 Next Steps After Setup

1. **Seed Demo Data**: After signing in, go to Profile → Demo Utilities → Seed Demo Data
2. **Test Features**: Try creating campaigns, calendar items, and templates
3. **Configure Notifications**: Test notification onboarding flow
4. **Verify Subscriptions**: Test subscription purchase flow (use StoreKit config file)

## 📚 Additional Resources

- See `README.md` for feature overview
- See `Docs/ArchitectureOverview.md` for code structure
- CloudKit Dashboard: https://icloud.developer.apple.com/dashboard/
- App Store Connect: https://appstoreconnect.apple.com/

---

**Support**: Email support@bradleyvirtualsolutions.com for questions.


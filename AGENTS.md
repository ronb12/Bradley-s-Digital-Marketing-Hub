# AGENTS.md — Bradley Digital Marketing Hub

Native iOS 17+ SwiftUI app for marketing planning, content generation, calendars, affiliates, bookings, and StoreKit subscriptions. Data lives in CloudKit; auth uses Sign in with Apple.

## Repository layout

- `Bradley Digital Marketing Hub/` — app source (`Models/`, `ViewModels/`, `Views/`, `Services/`, `Supporting/`)
- `Bradley Digital Marketing Hub.xcodeproj` — Xcode project (open on macOS with Xcode 15+)
- `Bradley Digital Marketing HubTests/` — unit tests (`HubQualityTests`)
- `Bradley Digital Marketing HubUITests/` — UI tests
- `Docs/` — legal and architecture docs (also published to GitHub Pages for privacy policy)
- `ci_scripts/` — Xcode Cloud scripts

Do not commit build artifacts (`build/`, `BuildOutput/`, `DerivedData/`, `*.ipa`). They are gitignored.

## Architecture

- **MVVM**: SwiftUI views bind to `@MainActor` `ObservableObject` view models; services hold CloudKit, auth, StoreKit, and social scheduling logic.
- **Entry**: `BradleyDigitalMarketingHubApp.swift` → `RootView` → tab navigation (Home, Calendar, Templates, Affiliate, Profile) plus Tools hub.
- **State**: `AppViewModel` coordinates auth, brands, campaigns, calendar, templates, affiliate tools, demo mode, and paywall.
- **Persistence**: `CloudKitService` + `MarketingModels.swift` record types (`UserProfile`, `Brand`, `CampaignPlan`, `ContentCalendarItem`, `TemplateItem`, `AffiliateTool`, bookings, social accounts).
- **Monetization**: `SubscriptionManager` + StoreKit 2; tiers in `SubscriptionTier` with product IDs `dmhub.pro.monthly` and `dmhub.agency.monthly`.
- **Theming**: `ThemeManager` — prefer theme tokens over hardcoded colors in new UI.

## Working agreements

1. **Platform**: Target iOS 17+. Use SwiftUI (`NavigationStack`, `TabView`), async/await, and `@MainActor` where UI state is touched.
2. **Scope**: Keep diffs minimal and feature-focused. Match existing naming, folder structure, and patterns in neighboring files.
3. **CloudKit**: Container ID is `AppConstants.cloudKitContainerIdentifier` in `Supporting/Constants.swift` (`iCloud.com.bradleyhub.app`). New record types belong in `MarketingModels.swift` with `CloudKitRecordConvertible` conformance; wire CRUD in `CloudKitService`.
4. **Subscriptions**: Quotas and gating use `SubscriptionTier` helpers (`maxCampaignPlans`, `maxCalendarItems`, `maxBrands`, template access). Do not bypass tier checks in UI or services.
5. **Social posting**: There is no live OAuth posting API in-app. User flows use Share Sheet / manual share copy; error messages must stay honest (see `SocialMediaError` and existing tests).
6. **Demo mode**: `DemoData` and `AppViewModel.isDemoMode` provide read-only sample data; do not write to CloudKit while demo mode is active.
7. **Comments**: Only for non-obvious business rules; prefer self-explanatory code.
8. **Tests**: When changing social errors, platform colors, or tier logic, extend `HubQualityTests` with behavior-focused assertions (not trivial getters).

## Build and verify (macOS)

```bash
# From repo root, after opening the project in Xcode once to resolve signing:
xcodebuild -project "Bradley Digital Marketing Hub.xcodeproj" \
  -scheme "Bradley Digital Marketing Hub" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

xcodebuild -project "Bradley Digital Marketing Hub.xcodeproj" \
  -scheme "Bradley Digital Marketing Hub" \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  test
```

Linux CI agents cannot run `xcodebuild`; rely on tests locally or Xcode Cloud for full compile verification.

## Setup reminders for contributors

- Bundle ID / signing: Xcode target **Signing & Capabilities**
- Enable **Sign in with Apple** and **CloudKit** with a container matching `Constants.swift`
- Configure StoreKit products in App Store Connect to match `SubscriptionTier.productIdentifier`
- Optional: Profile → Demo Utilities → **Seed Demo Data** for CloudKit sample content

## Product and docs

- User-facing setup: `README.md`
- Architecture: `Docs/ArchitectureOverview.md`
- CloudKit schema notes: `CLOUDKIT_SETUP.md`, comments in `CloudKitService.swift`

When adding features, update `README.md` or `Docs/` only if behavior or setup steps change for users or reviewers.

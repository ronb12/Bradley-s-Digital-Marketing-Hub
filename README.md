# Bradley Digital Marketing Hub

Bradley Digital Marketing Hub is a native iOS 17+ SwiftUI application that helps entrepreneurs and agencies plan marketing campaigns, generate content, manage affiliate workflows, and book premium marketing services—100% on Apple's stack.

## Features
- SwiftUI navigation with Home, Calendar, Templates, Affiliate, and Profile tabs
- CloudKit-powered storage for users, brands, campaigns, content calendars, templates, affiliate tools, and bookings
- Deterministic copy generator and guided campaign planner with tone, platform, and goal inputs
- Content calendar with quota enforcement per subscription tier
- Paywall and StoreKit 2 subscriptions for Free, Pro, and Agency plans
- Sign in with Apple onboarding and notifications primer
- Affiliate link logging via CloudKit and SFSafariViewController deep links
- Booking workflow for consultations and services with future payment integration placeholder

## Tech Stack
- SwiftUI + NavigationStack + TabView
- CloudKit (private + public databases)
- Sign in with Apple (AuthenticationServices)
- StoreKit 2 for Pro/Agency subscriptions
- MVVM-inspired architecture with dedicated Services and ViewModels

## Monetization Model
| Plan | Price | Highlights |
| ---- | ----- | ---------- |
| Free | Included | 3 campaigns, 10 calendar items, core templates, affiliate list |
| Pro | `dmhub.pro.monthly` | Unlimited campaigns/calendar, premium templates, pro affiliate picks |
| Agency | `dmhub.agency.monthly` | 10 brands, agency-only templates, exports, team-ready workflows |

Update StoreKit 2 product IDs inside `SubscriptionTier.productIdentifier` and match them with App Store Connect before shipping.

## Project Structure
```
Bradley-Digital-Marketing-Hub
├─ Bradley Digital Marketing Hub.xcodeproj
├─ Bradley Digital Marketing Hub/
│  ├─ Models / ViewModels / Views / Services / Supporting
│  ├─ Assets.xcassets / Preview Content
│  └─ Info.plist
├─ Docs/
│  ├─ MarketingPlanPlaceholder.md
│  ├─ AffiliateStrategy.md
│  ├─ ArchitectureOverview.md
│  ├─ TermsOfService.md
│  └─ PrivacyPolicy.md
├─ README.md
├─ LICENSE
└─ .gitignore
```

## Setup Instructions
1. **Open in Xcode**: Double-click `Bradley Digital Marketing Hub.xcodeproj` (requires Xcode 15+).
2. **Bundle ID & Signing**: Update the bundle identifier in the project settings and select your Apple developer team.
3. **CloudKit Container**: Replace `AppConstants.cloudKitContainerIdentifier` with your iCloud container. Provision matching record types (UserProfile, Brand, CampaignPlan, etc.) in CloudKit Dashboard.
4. **StoreKit 2**: Configure `dmhub.pro.monthly` and `dmhub.agency.monthly` in App Store Connect or change the identifiers in `SubscriptionTier` to match your products.
5. **Sign in with Apple**: Enable Sign in with Apple capability in the Signing & Capabilities tab.
6. **Run**: Choose an iPhone or iPad target running iOS 17+ and press **Run**.

## CloudKit Record Guidance
Each record type is defined in `Models/MarketingModels.swift`. Comments in `CloudKitService` highlight where to add new record logic, modify quotas, or seed template/affiliate data.

## Future Roadmap
- In-app analytics dashboards for campaign performance
- Push notification scheduling + actionable reminders
- Collaboration features for multi-user agencies
- SwiftData-powered offline cache + Spotlight search
- Web dashboard companion for reporting and approvals

## Legal
- Review the [Terms of Service](Docs/TermsOfService.md).
- Read the [Privacy Policy](Docs/PrivacyPolicy.md) to understand how CloudKit data is handled.

## Support
For questions or consulting, email `support@bradleyvirtualsolutions.com`.

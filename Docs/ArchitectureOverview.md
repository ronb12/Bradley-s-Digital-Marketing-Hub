# Architecture Overview

## Layers
- **Views** – SwiftUI screens organized by feature folder (Home, Calendar, Templates, Affiliate, Profile, Shared components).
- **ViewModels** – ObservableObjects per feature that coordinate user input, business rules, and service calls.
- **Services** – Reusable classes for CloudKit, authentication, and StoreKit 2 subscriptions.
- **Supporting** – Constants, extensions, and helpers shared across modules.

## CloudKitService
`CloudKitService` wraps the public and private databases defined by `AppConstants.cloudKitContainerIdentifier`. Each model in `Models/MarketingModels.swift` conforms to `CloudKitRecordConvertible` so saving/fetching records reuses generic helpers. Add new record types by extending the model file and calling the generic helpers.

## SubscriptionManager
`SubscriptionManager` loads StoreKit 2 products (`dmhub.pro.monthly`, `dmhub.agency.monthly`), performs purchases/restores, and publishes the active `SubscriptionTier`. `PaywallView` and `AppViewModel` reactively update UI and sync the chosen tier back to CloudKit via `updatePlan(to:)`.

## Authentication Flow
`WelcomeView` uses `SignInWithAppleButton`. `AppViewModel` routes the authorization result through `AuthService`, which extracts the Apple user identifier, caches it locally, and either fetches or creates a `UserProfile` record in the private database. After the notification onboarding screen, the main tab experience loads with all data fetched via `refreshPortal()`.

import SwiftUI
import AuthenticationServices

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel

    var body: some View {
        Group {
            switch appViewModel.authState {
            case .loading:
                ProgressView("Preparing your workspace...")
                    .progressViewStyle(.circular)
            case .onboarding:
                WelcomeView()
            case .notificationsOnboarding:
                NotificationsOnboardingView()
            case .authenticated:
                MainTabView()
            }
        }
        .task {
            await appViewModel.bootstrap()
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { appViewModel.errorMessage != nil },
            set: { _ in appViewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(appViewModel.errorMessage ?? "Unknown error")
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var subscriptionManager: SubscriptionManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                ContentCalendarView(service: appViewModel.cloudKitService)
            }
            .tabItem {
                Label("Calendar", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                TemplatesView()
            }
            .tabItem {
                Label("Templates", systemImage: "doc.richtext")
            }
            .tag(2)

            NavigationStack {
                AffiliateToolsView()
            }
            .tabItem {
                Label("Affiliate", systemImage: "link")
            }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(4)
        }
        .sheet(isPresented: $appViewModel.showPaywall) {
            PaywallView()
                .environmentObject(subscriptionManager)
                .presentationDetents([.fraction(0.75), .large])
        }
    }
}

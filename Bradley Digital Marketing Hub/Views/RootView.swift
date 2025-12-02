import SwiftUI
import AuthenticationServices
import UIKit

struct RootView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        Group {
            switch appViewModel.authState {
            case .loading:
                ZStack {
                    themeManager.colors(for: systemColorScheme).background
                        .ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(2.0)
                            .tint(themeManager.colors(for: systemColorScheme).primary)
                        Text("Preparing your workspace...")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                    }
                }
            case .onboarding:
                WelcomeView()
            case .notificationsOnboarding:
                NotificationsOnboardingView()
            case .authenticated:
                MainTabView()
            }
        }
        .preferredColorScheme(themeManager.selectedColorScheme == .system ? nil : (themeManager.selectedColorScheme == .light ? .light : .dark))
        .tint(themeManager.colors(for: themeManager.overrideColorScheme ?? systemColorScheme).primary)
        .task {
            // Bootstrap the app
            await appViewModel.bootstrap()
        }
        .onAppear {
            // Immediately transition if stuck in loading - show welcome screen right away
            if appViewModel.authState == .loading {
                // Transition immediately to show content
                appViewModel.authState = .onboarding
            }
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
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab = 0
    @State private var postToReviewId: String?
    @State private var showPostReview = false

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
                ContentCalendarView(service: appViewModel.cloudKitService, socialMediaService: appViewModel.socialMediaService)
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
        .sheet(isPresented: $showPostReview) {
            if let postId = postToReviewId {
                PostReviewContainerView(postId: postId)
                    .environmentObject(appViewModel)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenPostReview"))) { notification in
            if let userInfo = notification.userInfo,
               let postId = userInfo["postId"] as? String {
                postToReviewId = postId
                selectedTab = 1 // Switch to Calendar tab
                showPostReview = true
            }
        }
        .onAppear {
            setupNavigationBarAppearance()
        }
        .onChange(of: themeManager.selectedTheme) { _, _ in
            setupNavigationBarAppearance()
        }
        .onChange(of: colorScheme) { _, _ in
            setupNavigationBarAppearance()
        }
    }
    
    private func setupNavigationBarAppearance() {
        let colors = themeManager.colors(for: colorScheme)
        let primaryColor = UIColor(colors.primary)
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // In dark mode, use black background. In light mode, use theme surface color
        if colorScheme == .dark {
            appearance.backgroundColor = UIColor.black
        } else {
            appearance.backgroundColor = UIColor(colors.surface)
        }
        
        // Set title color to theme primary color
        appearance.titleTextAttributes = [
            .foregroundColor: primaryColor,
            .font: UIFont.boldSystemFont(ofSize: 17)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: primaryColor,
            .font: UIFont.boldSystemFont(ofSize: 34)
        ]
        
        // Apply to all navigation bars
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Set tint color for bar button items
        UINavigationBar.appearance().tintColor = primaryColor
    }
}

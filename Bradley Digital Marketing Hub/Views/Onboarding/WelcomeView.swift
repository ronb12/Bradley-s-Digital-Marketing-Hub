import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let colors = themeManager.colors(for: colorScheme)
        
        return ZStack {
            // Gradient background using theme colors
            LinearGradient(
                gradient: Gradient(colors: [
                    colors.primary,
                    colors.secondary
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)
                    
                    // App Icon/Logo Area
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 32)
                    
                    // Title Section
                    VStack(spacing: 16) {
                        Text("Bradley Digital")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Marketing Hub")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Plan campaigns, generate content, and grow your business with Apple-native tools")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                    }
                    .padding(.bottom, 48)
                    
                    // Feature Highlights
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "calendar.badge.clock",
                            title: "Content Calendar",
                            description: "Schedule and organize your marketing content"
                        )
                        
                        FeatureRow(
                            icon: "doc.richtext.fill",
                            title: "Smart Templates",
                            description: "AI-powered content generation for all platforms"
                        )
                        
                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Campaign Planner",
                            description: "Strategic planning tools for marketing success"
                        )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 48)
                    
                    // Action Buttons
                    VStack(spacing: 16) {
                        SignInWithAppleButton(.continue) { request in
                            appViewModel.prepareSignInRequest(request)
                        } onCompletion: { result in
                            appViewModel.handleSignInResult(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        
                        Button {
                            appViewModel.enterDemoMode()
                        } label: {
                            HStack {
                                Image(systemName: "eye.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Explore Demo Mode")
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(.white.opacity(0.2))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    
                    // Footer Text
                    VStack(spacing: 12) {
                        Text("Preview the app with sample data before signing in")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 11))
                            Text("Secure authentication with Sign in with Apple")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(16)
        .background(.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }
}

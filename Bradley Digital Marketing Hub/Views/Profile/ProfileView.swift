import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var isSeedingDemoData = false
    @State private var demoSeedStatus: String?
    @State private var avatarSelection: PhotosPickerItem?
    @State private var pendingAvatarImage: Image?
    @State private var isUploadingAvatar = false
    @State private var avatarStatusMessage: String?

    var body: some View {
        List {
            Section(header: Text("Account")) {
                HStack(alignment: .center, spacing: 16) {
                    avatarPreview
                    VStack(alignment: .leading, spacing: 6) {
                        Text(appViewModel.userProfile?.name ?? "Unknown")
                            .font(.headline)
                        Text(appViewModel.userProfile?.email ?? "No email on file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack {
                            Text("Plan")
                            Spacer()
                            Text(appViewModel.currentTier.displayName)
                                .bold()
                        }
                    }
                }
                
                Button("Manage Subscription") {
                    appViewModel.showPaywall = true
                }
            }
            
            // Profile Editing Section - Always Visible and Prominent
            Section(header: Text("Edit Profile")) {
                // Name field - Always visible, prominent at top
                VStack(alignment: .leading, spacing: 4) {
                    Text("Full Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Enter your name", text: $profileViewModel.userName, prompt: Text("Enter your name"))
                        .autocapitalization(.words)
                        .disabled(profileViewModel.isUpdatingProfile || appViewModel.isDemoMode)
                }
                .padding(.vertical, 4)
                
                // Photo upload - Make it prominent
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Photo")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    PhotosPicker(selection: $avatarSelection, matching: .images) {
                        HStack {
                            if isUploadingAvatar {
                                ProgressView()
                            } else {
                                Image(systemName: appViewModel.userProfile?.avatarAssetURL != nil || pendingAvatarImage != nil ? "photo.fill" : "photo.badge.plus")
                                    .foregroundColor(themeManager.colors(for: colorScheme).primary)
                                    .font(.title3)
                            }
                            Text(appViewModel.userProfile?.avatarAssetURL != nil || pendingAvatarImage != nil ? "Change Photo" : "Add Photo")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(appViewModel.isDemoMode ? Color.gray.opacity(0.1) : Color.clear)
                        .cornerRadius(8)
                    }
                    .disabled(appViewModel.isDemoMode || isUploadingAvatar)
                    
                    if let message = avatarStatusMessage {
                        Text(message)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                if (appViewModel.userProfile?.avatarAssetURL != nil || pendingAvatarImage != nil) && !appViewModel.isDemoMode {
                    Button("Remove Photo", role: .destructive) {
                        Task {
                            isUploadingAvatar = true
                            await appViewModel.removeAvatar()
                            pendingAvatarImage = nil
                            isUploadingAvatar = false
                            avatarStatusMessage = "Avatar removed."
                        }
                    }
                }
                
                // Save button
                if !appViewModel.isDemoMode {
                    Button {
                        Task {
                            await profileViewModel.updateUserProfile(appViewModel: appViewModel)
                        }
                    } label: {
                        if profileViewModel.isUpdatingProfile {
                            HStack {
                                ProgressView()
                                    .tint(.white)
                                Text("Saving...")
                            }
                        } else {
                            Text("Save Changes")
                        }
                    }
                    .disabled(profileViewModel.isUpdatingProfile || profileViewModel.userName.isEmpty)
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.colors(for: colorScheme).primary)
                    .frame(maxWidth: .infinity)
                } else {
                    Text("Sign in with Apple to edit your profile")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
                
                if let message = profileViewModel.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(message.contains("Failed") || message.contains("Error") ? .red : .secondary)
                }
            }
            
            // Additional Profile Information Editing
            if !appViewModel.isDemoMode {
                Section(header: Text("Additional Information")) {
                    TextField("Business Name", text: $profileViewModel.businessName, prompt: Text("Enter business name"))
                        .autocapitalization(.words)
                        .disabled(profileViewModel.isUpdatingProfile)
                    
                    Picker("Business Type", selection: $profileViewModel.userBusinessTypeOption) {
                        ForEach(BusinessType.allWithCustom) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    .disabled(profileViewModel.isUpdatingProfile)
                    
                    if case .custom = profileViewModel.userBusinessTypeOption {
                        TextField("Enter business type", text: $profileViewModel.customUserBusinessType, prompt: Text("Custom business type"))
                            .autocapitalization(.words)
                            .disabled(profileViewModel.isUpdatingProfile)
                    }
                }
            }
            
            Section(header: Text("Social Media")) {
                NavigationLink {
                    SocialAccountsView(service: appViewModel.socialMediaService)
                        .environmentObject(appViewModel)
                        .environmentObject(themeManager)
                } label: {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .foregroundColor(themeManager.colors(for: colorScheme).primary)
                        Text("Connected Accounts")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            
            Section(header: Text("Appearance")) {
                // App Theme Picker with themed icon
                LabeledContent {
                    Picker("App Theme", selection: $themeManager.selectedTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(Color.themePrimary(for: theme, colorScheme: colorScheme))
                                    .frame(width: 20, height: 20)
                                Image(systemName: theme.iconName)
                                    .foregroundColor(Color.themePrimary(for: theme, colorScheme: colorScheme))
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .labelsHidden()
                    .tint(themeManager.colors(for: colorScheme).primary)
                } label: {
                    Label {
                        Text("App Theme")
                    } icon: {
                        Image(systemName: themeManager.selectedTheme.iconName)
                            .foregroundColor(themeManager.colors(for: colorScheme).primary)
                    }
                }
                
                // Theme preview
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Circle()
                                .fill(themeManager.colors(for: colorScheme).primary)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(themeManager.colors(for: colorScheme).secondary)
                                .frame(width: 16, height: 16)
                            Circle()
                                .fill(themeManager.colors(for: colorScheme).accent)
                                .frame(width: 16, height: 16)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                
                // Appearance Mode Picker with themed icon
                LabeledContent {
                    Picker("Appearance Mode", selection: $themeManager.selectedColorScheme) {
                        ForEach([AppColorScheme.light, .dark, .system], id: \.self) { scheme in
                            HStack {
                                Image(systemName: scheme == .light ? "sun.max.fill" : scheme == .dark ? "moon.fill" : "circle.lefthalf.filled")
                                    .foregroundColor(themeManager.colors(for: colorScheme).primary)
                                Text(scheme.displayName)
                            }
                            .tag(scheme)
                        }
                    }
                    .labelsHidden()
                    .tint(themeManager.colors(for: colorScheme).primary)
                } label: {
                    Label {
                        Text("Appearance Mode")
                    } icon: {
                        Image(systemName: themeManager.selectedColorScheme == .light ? "sun.max.fill" : themeManager.selectedColorScheme == .dark ? "moon.fill" : "circle.lefthalf.filled")
                            .foregroundColor(themeManager.colors(for: colorScheme).primary)
                    }
                }
            }

            Section(header: Text("Brands"), footer: Text("Agency plan supports up to 10 brands.")) {
                ForEach(appViewModel.brands) { brand in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(brand.name)
                            Text(brand.industry).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if appViewModel.selectedBrand?.id == brand.id {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        appViewModel.selectedBrand = brand
                    }
                }
                if appViewModel.canAddBrand() {
                    TextField("Brand name", text: $profileViewModel.brandName)
                        .autocapitalization(.words)
                    
                    Picker("Industry", selection: $profileViewModel.brandIndustryOption) {
                        ForEach(BusinessType.allWithCustom) { option in
                            Text(option.displayName).tag(option)
                        }
                    }
                    
                    // Custom Industry TextField (shown only when custom is selected)
                    if case .custom = profileViewModel.brandIndustryOption {
                        TextField("Enter industry", text: $profileViewModel.customIndustry)
                            .autocapitalization(.words)
                    }
                    
                    Picker("Brand Color", selection: $profileViewModel.brandColorOption) {
                        ForEach(BrandColor.allWithCustom) { option in
                            HStack {
                                Circle()
                                    .fill(Color(hex: option.hexValue ?? "#5B8DEF"))
                                    .frame(width: 20, height: 20)
                                Text(option.displayName)
                            }
                            .tag(option)
                        }
                    }
                    
                    // Custom Color TextField (shown only when custom is selected)
                    if case .custom = profileViewModel.brandColorOption {
                        TextField("Enter hex color (e.g., #FF5733)", text: $profileViewModel.customColorHex)
                            .autocapitalization(.none)
                            .keyboardType(.default)
                    }
                    
                    Button("Add brand") {
                        Task {
                            guard let userId = appViewModel.userProfile?.userId else { return }
                            let brand = Brand(
                                userId: userId,
                                name: profileViewModel.brandName,
                                industry: profileViewModel.brandIndustry,
                                colorHex: profileViewModel.brandColorHex
                            )
                            await appViewModel.saveBrand(brand)
                            profileViewModel.reset()
                        }
                    }
                } else {
                    Text("Upgrade to Agency to add more brands.")
                        .foregroundColor(.secondary)
                }
            }

            if appViewModel.isDemoMode {
                Section(header: Text("Demo Mode")) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(themeManager.colors(for: colorScheme).primary)
                        Text("You are browsing demo data. Sign in with Apple for a personal workspace.")
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Section(header: Text("Demo Utilities"), footer: Text("Seeds CloudKit with sample brands, campaigns, templates, and affiliate tools.")) {
                    Button {
                        guard !isSeedingDemoData else { return }
                        isSeedingDemoData = true
                        demoSeedStatus = "Seeding demo data..."
                        Task {
                            do {
                                let result = try await appViewModel.seedDemoData()
                                demoSeedStatus = result.summary
                            } catch {
                                demoSeedStatus = error.localizedDescription
                            }
                            isSeedingDemoData = false
                        }
                    } label: {
                        if isSeedingDemoData {
                            HStack {
                                ProgressView()
                                Text("Seeding Demo Data…")
                            }
                        } else {
                            Label("Seed Demo Data", systemImage: "shippingbox.fill")
                        }
                    }
                    .disabled(isSeedingDemoData)

                    if let status = demoSeedStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section {
                Button("Sign out", role: .destructive) {
                    appViewModel.signOut()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .onAppear {
            // Load current profile data into edit fields
            profileViewModel.loadUserProfile(appViewModel.userProfile)
        }
        .onChange(of: appViewModel.userProfile) { oldValue, newValue in
            // Reload when profile changes
            profileViewModel.loadUserProfile(newValue)
        }
        .onChange(of: avatarSelection) { oldValue, newValue in
            guard let selection = newValue, !appViewModel.isDemoMode else { return }
            Task {
                do {
                    guard let data = try await selection.loadTransferable(type: Data.self),
                          let processed = processedAvatarData(from: data) else {
                        avatarStatusMessage = "Unsupported image format."
                        return
                    }
                    isUploadingAvatar = true
                    if let image = Image(data: processed) {
                        pendingAvatarImage = image
                    }
                    await appViewModel.updateAvatar(with: processed)
                    avatarStatusMessage = "Avatar updated."
                } catch {
                    avatarStatusMessage = error.localizedDescription
                }
                isUploadingAvatar = false
            }
        }
    }

    private var avatarPreview: some View {
        Group {
            if let image = currentAvatarImage() {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .padding(12)
            }
        }
        .frame(width: 72, height: 72)
        .background(Color.hubBackground, in: Circle())
        .clipShape(Circle())
    }

    private func currentAvatarImage() -> Image? {
        if let pendingAvatarImage {
            return pendingAvatarImage
        }
        if let url = appViewModel.userProfile?.avatarAssetURL,
           let data = try? Data(contentsOf: url),
           let image = Image(data: data) {
            return image
        }
        return nil
    }

    private func processedAvatarData(from data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return nil }
        let maxDimension: CGFloat = 512
        let size = uiImage.size
        let maxSide = max(size.width, size.height)
        let scale = maxSide > maxDimension ? maxDimension / maxSide : 1
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        uiImage.draw(in: CGRect(origin: .zero, size: targetSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resized?.jpegData(compressionQuality: 0.85)
    }
}

private extension Image {
    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else { return nil }
        self = Image(uiImage: uiImage)
    }
}

import SwiftUI
import PhotosUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
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
                PhotosPicker(selection: $avatarSelection, matching: .images) {
                    HStack {
                        if isUploadingAvatar {
                            ProgressView()
                        }
                        Text("Update Photo")
                    }
                }
                .disabled(appViewModel.isDemoMode || isUploadingAvatar)
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
                if let message = avatarStatusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Button("Manage Subscription") {
                    appViewModel.showPaywall = true
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
                    TextField("Industry", text: $profileViewModel.brandIndustry)
                    TextField("Color hex", text: $profileViewModel.brandColorHex)
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
                    Text("You are browsing demo data. Sign in with Apple for a personal workspace.")
                        .foregroundColor(.secondary)
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
        .onChange(of: avatarSelection) { newValue in
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

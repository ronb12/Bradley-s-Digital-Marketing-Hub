import SwiftUI

struct SocialAccountsView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel: SocialAccountsViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(service: SocialMediaService) {
        _viewModel = StateObject(wrappedValue: SocialAccountsViewModel(service: service))
    }
    
    var body: some View {
        List {
            Section(header: Text("Connected Accounts")) {
                if viewModel.connectedAccounts.isEmpty {
                    Text("No accounts connected")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(viewModel.connectedAccounts) { account in
                        HStack {
                            Image(systemName: SocialPlatform(rawValue: account.platform)?.iconName ?? "link")
                                .foregroundColor(themeManager.colors(for: colorScheme).primary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.accountName)
                                    .font(.headline)
                                Text(account.platform)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if account.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Text("Inactive")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            for index in indexSet {
                                await viewModel.disconnectAccount(viewModel.connectedAccounts[index])
                            }
                        }
                    }
                }
            }
            
            Section(header: Text("Connect Account"), footer: Text("Connect your social media accounts to enable automatic posting. Posts will be published at their scheduled times.")) {
                ForEach(SocialPlatform.allCases) { platform in
                    Button {
                        Task {
                            await viewModel.connectAccount(platform: platform)
                        }
                    } label: {
                        HStack {
                            Image(systemName: platform.iconName)
                                .foregroundColor(themeManager.colors(for: colorScheme).primary)
                                .frame(width: 24)
                            Text(platform.rawValue)
                            Spacer()
                            if viewModel.connectedAccounts.contains(where: { $0.platform == platform.rawValue && $0.isActive }) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    .disabled(viewModel.isConnecting)
                }
            }
            
            if viewModel.isConnecting {
                Section {
                    HStack {
                        ProgressView()
                        Text("Connecting account...")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let message = viewModel.statusMessage {
                Section {
                    Text(message)
                        .foregroundColor(message.contains("error") || message.contains("failed") ? .red : .secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Social Accounts")
        .task {
            if let userId = appViewModel.userProfile?.userId {
                viewModel.setUserId(userId)
            }
            await viewModel.loadAccounts()
        }
    }
}

@MainActor
final class SocialAccountsViewModel: ObservableObject {
    @Published var connectedAccounts: [ConnectedSocialAccount] = []
    @Published var isConnecting = false
    @Published var statusMessage: String?
    
    private let service: SocialMediaService
    private var userId: String?
    
    init(service: SocialMediaService) {
        self.service = service
    }
    
    func loadAccounts() async {
        guard let userId = userId else {
            // Get userId from AppViewModel via environment
            statusMessage = "Please sign in to connect accounts"
            return
        }
        do {
            connectedAccounts = try await service.fetchConnectedAccounts(userId: userId)
        } catch {
            statusMessage = "Error loading accounts: \(error.localizedDescription)"
        }
    }
    
    func connectAccount(platform: SocialPlatform) async {
        guard let userId = userId else {
            statusMessage = "Error: User not found. Please sign in."
            return
        }
        
        // Check if already connected
        if connectedAccounts.contains(where: { $0.platform == platform.rawValue && $0.isActive }) {
            statusMessage = "\(platform.rawValue) is already connected"
            return
        }
        
        isConnecting = true
        statusMessage = nil
        defer { isConnecting = false }
        
        do {
            let account = try await service.connectAccount(for: platform, userId: userId)
            await loadAccounts()
            statusMessage = "Successfully connected \(platform.rawValue)!"
        } catch {
            statusMessage = "Error connecting \(platform.rawValue): \(error.localizedDescription)"
        }
    }
    
    func disconnectAccount(_ account: ConnectedSocialAccount) async {
        do {
            try await service.disconnectAccount(account)
            await loadAccounts()
            statusMessage = "Disconnected \(account.platform)"
        } catch {
            statusMessage = "Error disconnecting account: \(error.localizedDescription)"
        }
    }
    
    func setUserId(_ userId: String) {
        self.userId = userId
    }
}


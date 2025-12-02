import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var brandName: String = ""
    @Published var brandIndustryOption: BusinessTypeOption = .predefined(.other)
    @Published var customIndustry: String = ""
    @Published var brandColorOption: BrandColorOption = .predefined(.blue)
    @Published var customColorHex: String = "#5B8DEF"
    @Published var statusMessage: String?
    
    // User profile editing
    @Published var userName: String = ""
    @Published var businessName: String = ""
    @Published var userBusinessTypeOption: BusinessTypeOption = .predefined(.other)
    @Published var customUserBusinessType: String = ""
    @Published var isUpdatingProfile: Bool = false

    var brandIndustry: String {
        switch brandIndustryOption {
        case .predefined(let type):
            return type.rawValue
        case .custom:
            return customIndustry.isEmpty ? "Other" : customIndustry
        }
    }
    
    var brandColorHex: String {
        if case .custom = brandColorOption {
            return customColorHex.isEmpty ? "#5B8DEF" : customColorHex
        } else if case .predefined(let color) = brandColorOption {
            return color.hexValue
        }
        return "#5B8DEF"
    }
    
    var userBusinessType: String {
        switch userBusinessTypeOption {
        case .predefined(let type):
            return type.rawValue
        case .custom:
            return customUserBusinessType.isEmpty ? "Other" : customUserBusinessType
        }
    }
    
    func loadUserProfile(_ profile: UserProfile?) {
        guard let profile = profile else { return }
        userName = profile.name ?? ""
        businessName = profile.businessName ?? ""
        
        // Load business type
        if let businessType = profile.businessType,
           let type = BusinessType.allCases.first(where: { $0.rawValue == businessType }) {
            userBusinessTypeOption = .predefined(type)
        } else if let businessType = profile.businessType, !businessType.isEmpty {
            userBusinessTypeOption = .custom
            customUserBusinessType = businessType
        } else {
            userBusinessTypeOption = .predefined(.other)
        }
    }
    
    func updateUserProfile(appViewModel: AppViewModel) async {
        guard !isUpdatingProfile, !appViewModel.isDemoMode else { return }
        guard var profile = appViewModel.userProfile else {
            statusMessage = "No profile found. Please sign in."
            return
        }
        
        isUpdatingProfile = true
        defer { isUpdatingProfile = false }
        
        // Update profile fields
        profile.name = userName.isEmpty ? nil : userName
        profile.businessName = businessName.isEmpty ? nil : businessName
        profile.businessType = userBusinessType.isEmpty ? nil : userBusinessType
        
        do {
            let saved = try await appViewModel.cloudKitService.upsertUserProfile(profile)
            await MainActor.run {
                appViewModel.userProfile = saved
                statusMessage = "Profile updated successfully."
                
                // Clear message after 3 seconds
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    statusMessage = nil
                }
            }
        } catch {
            statusMessage = "Failed to update profile: \(error.localizedDescription)"
        }
    }

    func reset() {
        brandName = ""
        brandIndustryOption = .predefined(.other)
        customIndustry = ""
        brandColorOption = .predefined(.blue)
        customColorHex = "#5B8DEF"
    }
}

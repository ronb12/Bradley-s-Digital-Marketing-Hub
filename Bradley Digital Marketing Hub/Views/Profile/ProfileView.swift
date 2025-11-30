import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @StateObject private var profileViewModel = ProfileViewModel()

    var body: some View {
        List {
            Section(header: Text("Account")) {
                Text(appViewModel.userProfile?.name ?? "Unknown")
                Text(appViewModel.userProfile?.email ?? "No email on file")
                HStack {
                    Text("Plan")
                    Spacer()
                    Text(appViewModel.currentTier.displayName)
                        .bold()
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

            Section {
                Button("Sign out", role: .destructive) {
                    appViewModel.signOut()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
    }
}

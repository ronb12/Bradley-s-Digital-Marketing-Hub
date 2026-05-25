import SwiftUI

struct SaveTemplateView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var isPremium = false
    @State private var isAgencyOnly = false
    @State private var isSaving = false
    @State private var statusMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Template Details") {
                    TextField("Template name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Access") {
                    Toggle("Premium template", isOn: $isPremium)
                    Toggle("Agency only", isOn: $isAgencyOnly)
                }

                if let statusMessage {
                    Section {
                        Text(statusMessage)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Save Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await saveTemplate() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveTemplate() async {
        guard !appViewModel.isDemoMode else {
            statusMessage = "Sign in with Apple to publish templates to CloudKit."
            return
        }

        isSaving = true
        defer { isSaving = false }

        let template = TemplateItem(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            isPremium: isPremium,
            isAgencyOnly: isAgencyOnly
        )

        do {
            let saved = try await appViewModel.cloudKitService.saveTemplate(template)
            await MainActor.run {
                appViewModel.templates.append(saved)
                HapticFeedback.success()
                dismiss()
            }
        } catch {
            statusMessage = error.localizedDescription
            HapticFeedback.warning()
        }
    }
}

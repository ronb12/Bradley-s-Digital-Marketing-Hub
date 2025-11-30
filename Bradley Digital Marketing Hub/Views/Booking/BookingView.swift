import SwiftUI

struct BookingView: View {
    @EnvironmentObject private var appViewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BookingViewModel

    init(service: CloudKitService) {
        _viewModel = StateObject(wrappedValue: BookingViewModel(service: service))
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Service type", selection: $viewModel.serviceType) {
                    Text("Consultation").tag("Consultation")
                    Text("Ad Audit").tag("Ad Audit")
                    Text("Funnel Build").tag("Funnel Build")
                }
                DatePicker("Preferred time", selection: $viewModel.requestedDate)
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
                Section(footer: Text("Payment link to be integrated later.")) {
                    Button("Submit booking") {
                        Task {
                            if let userId = appViewModel.userProfile?.userId {
                                await viewModel.submit(userId: userId)
                                if viewModel.statusMessage?.contains("received") == true {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                if let status = viewModel.statusMessage {
                    Text(status).foregroundColor(.secondary)
                }
            }
            .navigationTitle("Book a Service")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

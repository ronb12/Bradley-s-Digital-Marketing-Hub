import Foundation

@MainActor
final class BookingViewModel: ObservableObject {
    @Published var serviceType: ServiceType = .consultation
    @Published var requestedDate: Date = Date()
    @Published var notes: String = ""
    @Published var statusMessage: String?
    @Published var isSubmitting = false

    private let service: CloudKitService

    init(service: CloudKitService) {
        self.service = service
    }

    func submit(userId: String) async {
        isSubmitting = true
        defer { isSubmitting = false }
        let booking = Booking(
            userId: userId,
            serviceType: serviceType.rawValue,
            requestedTime: requestedDate,
            notes: notes
        )
        do {
            _ = try await service.saveBooking(booking)
            statusMessage = "Booking received! We'll confirm via email."
            notes = ""
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}

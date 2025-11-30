import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var brandName: String = ""
    @Published var brandIndustry: String = ""
    @Published var brandColorHex: String = "#5B8DEF"
    @Published var statusMessage: String?

    func reset() {
        brandName = ""
        brandIndustry = ""
        brandColorHex = "#5B8DEF"
    }
}

import XCTest
@testable import Bradley_Digital_Marketing_Hub

final class HubQualityTests: XCTestCase {
    func testHubPlatformColorsUsesThemePrimaryForFacebook() {
        let accent = HubPlatformColors.accent(for: "facebook", themePrimary: .red)
        XCTAssertEqual(accent, .red)
    }

    func testHubPlatformColorsUsesPurpleForInstagram() {
        let accent = HubPlatformColors.accent(for: "instagram", themePrimary: .blue)
        XCTAssertEqual(accent, .purple)
    }

    func testSocialMediaErrorDirectPostingMessageIsHonest() {
        let error = SocialMediaError.directPostingUnavailable
        XCTAssertTrue(error.errorDescription?.contains("Share Sheet") == true)
    }

    func testSocialMediaErrorAccountConnectionMessageIsHonest() {
        let error = SocialMediaError.accountConnectionUnavailable
        XCTAssertTrue(error.errorDescription?.contains("manually") == true)
    }
}

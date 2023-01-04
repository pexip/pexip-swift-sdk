import Foundation

/// An event that includes information to be displayed to the user.
public struct SplashScreenEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case key = "screen_key"
    }

    /// The key to find the corresponding splash screen theme.
    public let key: String
}

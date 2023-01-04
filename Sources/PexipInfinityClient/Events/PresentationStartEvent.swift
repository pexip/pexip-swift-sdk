import Foundation

/// An event that includes the information on which participant is presenting.
public struct PresentationStartEvent: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case presenterName = "presenter_name"
        case presenterUri = "presenter_uri"
    }

    /// The name of the presenter.
    public let presenterName: String

    /// The URI of the presenter.
    public let presenterUri: String

    /// Creates a new instance of ``PresentationStartEvent``
    ///
    /// - Parameters:
    ///   - presenterName: The name of the presenter
    ///   - presenterUri: The URI of the presenter
    public init(presenterName: String, presenterUri: String) {
        self.presenterName = presenterName
        self.presenterUri = presenterUri
    }
}

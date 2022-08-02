import Foundation

public struct Version: Codable, Hashable {
    private enum CodingKeys: String, CodingKey {
        case versionId = "version_id"
        case pseudoVersion = "pseudo_version"
    }

    public let versionId: String
    public let pseudoVersion: String

    // MARK: - Init

    public init(versionId: String, pseudoVersion: String) {
        self.versionId = versionId
        self.pseudoVersion = pseudoVersion
    }
}

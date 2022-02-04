import Foundation

public struct APIConfiguration {
    static func apiURL(forNode nodeAddress: URL) -> URL {
        nodeAddress.appendingPathComponent("api/client/v2")
    }

    public let nodeAddress: URL
    public let alias: String

    var apiURL: URL {
        APIConfiguration.apiURL(forNode: nodeAddress)
    }

    var conferenceBaseURL: URL {
        apiURL.appendingPathComponent("conferences/\(alias)")
    }

    func participantBaseURL(withUUID uuid: UUID) -> URL {
        conferenceBaseURL
            .appendingPathComponent("participants")
            .appendingPathComponent(uuid.uuidString.lowercased())
    }

    func callBaseURL(participantUUID: UUID, callUUID: UUID) -> URL {
        participantBaseURL(withUUID: participantUUID)
            .appendingPathComponent("calls")
            .appendingPathComponent(callUUID.uuidString.lowercased())
    }
}

import Foundation

struct APIConfiguration: Hashable {
    let uri: ConferenceURI
    let nodeAddress: URL
    
    func url(forRequest requestName: String) -> URL {
        let path = "/api/client/v2/conferences/\(uri.alias)/\(requestName)"
        return nodeAddress.appendingPathComponent(path)
    }
}

import Foundation
import PexipInfinityClient

struct ConferenceDetails: Identifiable, Hashable {
    let id = UUID()
    let node: URL
    let alias: ConferenceAlias
    let token: ConferenceToken
}

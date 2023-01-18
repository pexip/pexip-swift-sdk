import Foundation
import PexipInfinityClient

enum Screen: Equatable, Hashable {
    case displayName
    case alias
    case pinChallenge(
        alias: ConferenceAlias,
        node: URL,
        tokenError: ConferenceTokenError
    )
    case conference(ConferenceDetails, preflight: Bool)
}

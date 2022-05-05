import SwiftUI
import PexipInfinityClient
import PexipConference

final class PinChallengeViewModel: ObservableObject {
    typealias Complete = (Token) -> Void

    @Published var pin = ""
    @Published var isPinRequired = false
    @Published var errorMessage: String?
    @AppStorage("displayName") private(set) var displayName = "Guest"
    @MainActor var isValid: Bool {
        !pin.isEmpty || !isPinRequired
    }

    private let tokenService: TokenService
    private let onComplete: Complete

    // MARK: - Init

    init(
        tokenError: TokenError,
        tokenService: TokenService,
        onComplete: @escaping Complete
    ) {
        self.tokenService = tokenService
        self.onComplete = onComplete
        handleTokenError(tokenError)
    }

    // MARK: - Actions

    @MainActor
    func submitPin() async {
        do {
            let fields = RequestTokenFields(displayName: displayName)
            let token = try await tokenService.requestToken(
                fields: fields,
                pin: pin
            )
            pin = ""
            onComplete(token)
        } catch let error as TokenError {
            debugPrint(error)
            handleTokenError(error)
        } catch {
            debugPrint(error)
            errorMessage = error.localizedDescription
        }
    }

    private func handleTokenError(_ error: TokenError) {
        switch error {
        case .invalidPin:
            errorMessage = "Incorrect PIN, please try again"
        case .pinRequired(let guestPinRequired):
            isPinRequired = guestPinRequired
        case .tokenDecodingFailed:
            errorMessage = "Something went wrong, please try again"
        case .conferenceExtensionRequired:
            errorMessage = "Virtual Reception conferences are not supported"
        case .ssoIdentityProviderRequired, .ssoIdentityProviderRedirect:
            errorMessage = "SSO is not supported"
        }
    }
}

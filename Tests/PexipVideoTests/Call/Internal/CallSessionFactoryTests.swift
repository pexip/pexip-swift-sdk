import XCTest
@testable import PexipVideo

final class CallSessionFactoryTests: XCTestCase {
    private var factory: CallSessionFactoryProtocol!
    private var urlSession: URLSession!
    private let node = Node(address: URL(string: "https://example.com")!)
    private let callConfiguration = CallConfiguration(
        qualityProfile: .medium,
        mediaFeatures: .all,
        useGoogleStunServersAsBackup: true
    )

    // MARK: - Setup

    override func setUpWithError() throws {
        try super.setUpWithError()
        urlSession = URLSession(configuration: .ephemeral)
        factory = CallSessionFactory(
            participantId: UUID(),
            iceServers: ["stun:stun.l.google.com:19302"],
            qualityProfile: .medium,
            callMediaFeatures: .all,
            apiClient: InfinityClient(
                node: Node(address: try XCTUnwrap(URL(string: "https://example.com"))),
                alias: try XCTUnwrap(.init(uri: "test@example.com")),
                urlSession: URLSession(configuration: .ephemeral),
                tokenProvider: nil,
                logger: SilentLogger()
            ),
            logger: SilentLogger()
        )
    }

    // MARK: - Tests

    func testCallTransceiver() throws {
        let callSession = factory.callTransceiver()
        XCTAssertFalse(try XCTUnwrap(callSession as? CallSession).isPresentation)
    }

    func testPresentationReceiver() throws {
        let callSession = factory.presentationReceiver()
        XCTAssertTrue(try XCTUnwrap(callSession as? CallSession).isPresentation)
    }
}

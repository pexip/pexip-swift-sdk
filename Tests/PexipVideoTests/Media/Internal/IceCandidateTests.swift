import XCTest
@testable import PexipVideo

final class IceCandidateTests: XCTestCase {
    func testInit() {
        let mid = "video"
        let pwd = "V9lFGGP4JotvV0MaRk+P+oHP"

        for ufrag in ["inKW", "Qt+9", "1/MvHwjAyVf27aLu"] {
            let candicate = candidate(withUfrag: ufrag)

            XCTAssertEqual(
                IceCandidate(candidate: candicate, mid: mid, pwd: pwd),
                IceCandidate(candidate: candicate, mid: mid, ufrag: ufrag, pwd: pwd)
            )
        }
    }

    func testPwd() {
        let pwd = "V9lFGGP4JotvV0MaRk+P+oHP"
        let string = "a=ice-ufrag:ciXE\r\na=ice-pwd:\(pwd)\r\na=ice-options:trickle "
        XCTAssertEqual(IceCandidate.pwd(from: string), pwd)
    }

    // MARK: - Helpers

    private func candidate(withUfrag ufrag: String) -> String {
        "... typ host tcptype passive generation 0 ufrag \(ufrag) network-id 2 network-cost 10"
    }
}

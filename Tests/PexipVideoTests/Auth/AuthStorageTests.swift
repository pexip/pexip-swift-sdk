import XCTest
import dnssd
@testable import PexipVideo

final class AuthStorageTests: XCTestCase {
    private var storage: AuthStorage!
    private var calendar: Calendar!
    private var createdAt: Date!
    private var currentDate = Date()
    private let connectionDetails = ConnectionDetails(
        participantUUID: UUID(),
        serviceType: .conference
    )
    
    // MARK: - Setup
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "GMT"))
        createdAt = try XCTUnwrap(
            DateComponents(
                calendar: calendar,
                year: 2022,
                month: 1,
                day: 27,
                hour: 13,
                minute: 16,
                second: 11
            ).date
        )
        storage = AuthStorage(currentDateProvider: { [unowned self] in
            self.currentDate
        })
    }
    
    // MARK: - Tests
    
    func testAuthToken() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)
        
        currentDate = createdAt.addingTimeInterval(60)
        try await storage.storeToken(token)
        let tokenFromStorage = try await storage.authToken()
        
        XCTAssertEqual(tokenFromStorage, token)
    }
    
    func testAuthTokenWithNewTokenTask() async throws {
        let token = AuthToken.randomToken(createdAt: createdAt)
        let newToken = AuthToken.randomToken(createdAt: createdAt)
        
        currentDate = createdAt.addingTimeInterval(60)
        try await storage.storeToken(token)
        
        let newTokenTask = Task<AuthToken, Error> {
            try await Task.sleep(seconds: 0.1)
            return newToken
        }
        try await storage.storeToken(withTask: newTokenTask)
        let tokenFromStorage = try await storage.authToken()

        XCTAssertEqual(tokenFromStorage, newToken)
    }
    
        
    func testStoreConnectionDetails() async {
        await storage.storeConnectionDetails(connectionDetails)
        let connectionDetailsFromStorage = await storage.connectionDetails()
        
        XCTAssertEqual(connectionDetailsFromStorage, connectionDetails)
    }
    
    func testClear() async throws {
        try await storage.storeToken(.randomToken(createdAt: createdAt))
        await storage.storeConnectionDetails(connectionDetails)
        
        let newTokenTask = Task<AuthToken, Error> {
            try await Task.sleep(seconds: 0.1)
            return .randomToken(createdAt: createdAt)
        }

        try await storage.storeToken(withTask: newTokenTask)
            
        await storage.clear()
        
        let tokenFromStorage = try await storage.authToken()
        XCTAssertNil(tokenFromStorage)
        
        let connectionDetailsFromStorage = await storage.connectionDetails()
        XCTAssertNil(connectionDetailsFromStorage)
        
        XCTAssertTrue(newTokenTask.isCancelled)
    }
}

// MARK: - Stubs

extension AuthToken {
    static func randomToken(
        createdAt: Date,
        expires: TimeInterval = 120
    ) -> AuthToken {
        AuthToken(
            value: UUID().uuidString,
            expires: "\(expires)",
            role: .guest,
            createdAt: createdAt
        )
    }
}

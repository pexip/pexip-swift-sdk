import Foundation

/// Conference splash screen service.
public protocol SplashScreenService {
    /**
     Fetches all available splash screens.
     - Parameters:
       - token: Current valid API token
     - Returns: A dictionary of splash screen objects
     - Throws: `HTTPError` if a network error was encountered during operation
     */
    func splashScreens(token: ConferenceToken) async throws -> [String: SplashScreen]

    /**
     - Parameters:
        - background: Splash screen background object
        - token: Current valid API token
     - Returns: The background image url for the given splash screen.
     */
    func backgroundURL(
        for background: SplashScreen.Background,
        token: ConferenceToken
    ) -> URL?
}

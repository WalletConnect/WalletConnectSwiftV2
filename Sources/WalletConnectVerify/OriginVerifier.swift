import Foundation

public final class OriginVerifier {
    enum Errors: Error {
        case registrationFailed
    }
    
    private var verifyHost: String
    /// The property is used to determine whether verify.walletconnect.org will be used
    /// in case verify.walletconnect.com doesn't respond for some reason (most likely due to being blocked in the user's location).
    private var fallback = false
    
    init(verifyHost: String) {
        self.verifyHost = verifyHost
    }
    
    func verifyOrigin(assertionId: String) async throws -> String {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 5.0
        sessionConfiguration.timeoutIntervalForResource = 5.0
        let session = URLSession(configuration: sessionConfiguration)
        
        let httpClient = HTTPNetworkClient(host: verifyHost, session: session)
        
        do {
            let response = try await httpClient.request(
                VerifyResponse.self,
                at: VerifyAPI.resolve(assertionId: assertionId)
            )
            guard let origin = response.origin else {
                throw Errors.registrationFailed
            }
            return origin
        } catch {
            if (error as? HTTPError) == .couldNotConnect && !fallback {
                fallback = true
                verifyHostFallback()
                return try await verifyOrigin(assertionId: assertionId)
            }
            throw error
        }
    }
    
    func verifyHostFallback() {
        verifyHost = "verify.walletconnect.org"
    }
}


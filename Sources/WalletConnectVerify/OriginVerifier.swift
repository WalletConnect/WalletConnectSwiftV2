import Foundation

public final class OriginVerifier {
    enum Errors: Error {
        case registrationFailed
    }
    
    private var verifyHost = "verify.walletconnect.org"

    func verifyOrigin(assertionId: String) async throws -> VerifyResponse {
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
            guard let _ = response.origin else {
                throw Errors.registrationFailed
            }
            return response
        } catch {
            throw error
        }
    }
}


import Foundation

public final class OriginVerifier {
    enum Errors: Error {
        case registrationFailed
    }
    
    private let verifyHost: String
    
    init(verifyHost: String) {
        self.verifyHost = verifyHost
    }
    
    func verifyOrigin(assertionId: String) async throws -> String {
        let httpClient = HTTPNetworkClient(host: verifyHost)
        let response = try await httpClient.request(
            VerifyResponse.self,
            at: VerifyAPI.resolve(assertionId: assertionId)
        )
        guard let origin = response.origin else {
            throw Errors.registrationFailed
        }
        return origin
    }
}


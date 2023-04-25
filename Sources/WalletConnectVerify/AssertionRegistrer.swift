import Foundation
import WalletConnectNetworking

public class AssertionRegistrer {
    enum Errors: Error {
        case registrationFailed
    }
    
    let verifyHost: String
    
    init(verifyHost: String) {
        self.verifyHost = verifyHost
    }
    
    func registerAssertion(attestationId: String) async throws -> String {
        let httpClient = HTTPNetworkClient(host: verifyHost)
        let response = try await httpClient.request(
            VerifyResponse.self,
            at: VerifyAPI.resolve(attestationId: attestationId)
        )
        guard let origin = response.origin else {
            throw Errors.registrationFailed
        }
        return origin
    }
}

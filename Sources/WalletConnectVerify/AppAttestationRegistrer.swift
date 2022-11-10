import Foundation
import DeviceCheck
import WalletConnectUtils

@available(iOS 14.0, *)
@available(macOS 11.0, *)
class AppAttestationRegistrer {

    private let service: DCAppAttestService
    private let logger: ConsoleLogging

    let AttestKeyGenerator: AttestKeyGenerating
    let AttestChallengeProvider: AttestChallengeProviding
    let KeyAttestationService: KeyAttesting

    init(logger: ConsoleLogging) throws {
        self.service = DCAppAttestService.shared
        self.logger = logger
        // TODO - check if attestation already performed
        generateKeys()
    }

    func registerAttestation() async throws {

    }

    private func generateKeys() {

    }

    private func getChallenge() {

    }

    private func attestKey() {

    }
}

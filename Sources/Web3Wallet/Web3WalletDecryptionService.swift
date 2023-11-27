import Foundation

public final class Web3WalletDecryptionService {

    private let signDecryptionService: SignDecryptionService

    public init(groupIdentifier: String) throws {
        self.signDecryptionService = try SignDecryptionService(groupIdentifier: groupIdentifier)
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> RPCRequest {
        return try signDecryptionService.decryptMessage(topic: topic, ciphertext: ciphertext)
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        signDecryptionService.getMetadata(topic: topic)
    }
}

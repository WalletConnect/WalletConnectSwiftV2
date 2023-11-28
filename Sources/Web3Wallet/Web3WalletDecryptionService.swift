import Foundation

public final class Web3WalletDecryptionService {
    enum Errors: Error {
        case unknownTag
    }
    public enum RequestMethod: UInt {
        case sessionRequest = 1108
        case sessionProposal = 1100
        case authRequest = 3000
    }

    private let signDecryptionService: SignDecryptionService
    private let authDecryptionService: AuthDecryptionService

    public init(groupIdentifier: String) throws {
        self.authDecryptionService = try AuthDecryptionService(groupIdentifier: groupIdentifier)
        self.signDecryptionService = try SignDecryptionService(groupIdentifier: groupIdentifier)
    }

    public static func getRequestMethod(tag: UInt) -> RequestMethod? {
        return RequestMethod(rawValue: tag)
    }

    public func decryptMessage(topic: String, ciphertext: String, tag: UInt) throws -> RPCRequest {
        guard let requestMethod = Self.getRequestMethod(tag: tag) else { throw Errors.unknownTag }
        switch requestMethod {
        case .sessionProposal, .sessionRequest:
            return try signDecryptionService.decryptMessage(topic: topic, ciphertext: ciphertext)
        case .authRequest:
            return try authDecryptionService.decryptMessage(topic: topic, ciphertext: ciphertext)
        }
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        if let metadata = signDecryptionService.getMetadata(topic: topic) {
            return metadata
        } else {
            return authDecryptionService.getMetadata(topic: topic)
        }
    }
}

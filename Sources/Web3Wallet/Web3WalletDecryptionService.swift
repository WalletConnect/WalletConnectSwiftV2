import Foundation

public final class Web3WalletDecryptionService {
    enum Errors: Error {
        case unknownTag
    }
    public enum RequestMethod: UInt {
        case sessionRequest = 1108
        case sessionProposal = 1100
        case authRequest = 1116
    }

    private let signDecryptionService: SignDecryptionService
    private static let w3wTags: [UInt] = [1108, 1100, 1116]

    public init(groupIdentifier: String) throws {
        self.signDecryptionService = try SignDecryptionService(groupIdentifier: groupIdentifier)
    }

    public static func canHandle(tag: UInt) -> Bool {
        return w3wTags.contains(tag)
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        signDecryptionService.getMetadata(topic: topic)
    }

    public func decryptMessage(topic: String, ciphertext: String, tag: UInt) throws -> DecryptedPayloadProtocol {
        guard let requestMethod = RequestMethod(rawValue: tag) else { throw Errors.unknownTag }
        switch requestMethod {
        case .sessionProposal:
            let proposal = try signDecryptionService.decryptProposal(topic: topic, ciphertext: ciphertext)
            return ProposalPayload(proposal: proposal)
        case .sessionRequest:
            let request = try signDecryptionService.decryptRequest(topic: topic, ciphertext: ciphertext)
            return RequestPayload(request: request)
        case .authRequest:
            let authRequest = try signDecryptionService.decryptAuthRequest(topic: topic, ciphertext: ciphertext)
            return AuthRequestPayload(authRequest: authRequest)
        }
    }


}

public protocol DecryptedPayloadProtocol {
    var requestMethod: Web3WalletDecryptionService.RequestMethod { get }
}

public struct RequestPayload: DecryptedPayloadProtocol {
    public var requestMethod: Web3WalletDecryptionService.RequestMethod { .sessionRequest }
    public var request: Request
}

public struct ProposalPayload: DecryptedPayloadProtocol {
    public var requestMethod: Web3WalletDecryptionService.RequestMethod { .sessionProposal }
    public var proposal: Session.Proposal
}

public struct AuthRequestPayload: DecryptedPayloadProtocol {
    public var requestMethod: Web3WalletDecryptionService.RequestMethod { .authRequest }
    public var authRequest: AuthenticationRequest
}

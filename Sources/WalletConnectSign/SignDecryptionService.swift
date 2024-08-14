import Foundation

public class SignDecryptionService {
    enum Errors: Error {
        case couldNotInitialiseDefaults
        case couldNotDecodeTypeFromCiphertext
    }
    private let serializer: Serializing
    private let sessionStorage: WCSessionStorage
    private let pairingStorage: PairingStorage

    public init(groupIdentifier: String) throws {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let kms = KeyManagementService(keychain: keychainStorage)
        self.serializer = Serializer(kms: kms, logger: ConsoleLogger(prefix: "🔐", loggingLevel: .off))
        guard let defaults = UserDefaults(suiteName: groupIdentifier) else {
            throw Errors.couldNotInitialiseDefaults
        }
        sessionStorage = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: defaults, identifier: SignStorageIdentifiers.sessions.rawValue)))
        pairingStorage = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: defaults, identifier: PairStorageIdentifiers.pairings.rawValue)))
    }

    public func decryptProposal(topic: String, ciphertext: String) throws -> Session.Proposal {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, codingType: .base64Encoded, envelopeString: ciphertext)
        if let proposal = try rpcRequest.params?.get(SessionType.ProposeParams.self) {
            return proposal.publicRepresentation(pairingTopic: topic)
        } else {
            throw Errors.couldNotDecodeTypeFromCiphertext
        }
    }

    public func decryptRequest(topic: String, ciphertext: String) throws -> Request {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, codingType: .base64Encoded, envelopeString: ciphertext)
        if let request = try rpcRequest.params?.get(SessionType.RequestParams.self),
           let rpcId = rpcRequest.id{
            let request = Request(
                id: rpcId,
                topic: topic,
                method: request.request.method,
                params: request.request.params,
                chainId: request.chainId,
                expiryTimestamp: request.request.expiryTimestamp
            )

            return request
        } else {
            throw Errors.couldNotDecodeTypeFromCiphertext
        }
    }

    public func decryptAuthRequest(topic: String, ciphertext: String) throws -> AuthenticationRequest {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, codingType: .base64Encoded, envelopeString: ciphertext)
        if let params = try rpcRequest.params?.get(SessionAuthenticateRequestParams.self),
           let id = rpcRequest.id {
            let authRequest = AuthenticationRequest(id: id, topic: topic, payload: params.authPayload, requester: params.requester.metadata)
            return authRequest
        } else {
            throw Errors.couldNotDecodeTypeFromCiphertext
        }
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        sessionStorage.getSession(forTopic: topic)?.peerParticipant.metadata
    }
}

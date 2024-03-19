import Foundation

public class AuthDecryptionService {
    enum Errors: Error {
        case couldNotInitialiseDefaults
        case couldNotDecodeTypeFromCiphertext
    }
    private let serializer: Serializing
    private let pairingStorage: PairingStorage

    public init(groupIdentifier: String) throws {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let kms = KeyManagementService(keychain: keychainStorage)
        self.serializer = Serializer(kms: kms, logger: ConsoleLogger(prefix: "🔐", loggingLevel: .off))
        guard let defaults = UserDefaults(suiteName: groupIdentifier) else {
            throw Errors.couldNotInitialiseDefaults
        }
        pairingStorage = PairingStorage(storage: SequenceStore<WCPairing>(store: .init(defaults: defaults, identifier: PairStorageIdentifiers.pairings.rawValue)))
    }

    public func decryptAuthRequest(topic: String, ciphertext: String) throws -> AuthRequest {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        setPairingMetadata(rpcRequest: rpcRequest, topic: topic)
        if let params = try rpcRequest.params?.get(Auth_RequestParams.self),
           let id = rpcRequest.id {
            let authRequest = AuthRequest(id: id, topic: topic, payload: params.payloadParams, requester: params.requester.metadata)
            return authRequest
        } else {
            throw Errors.couldNotDecodeTypeFromCiphertext
        }
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        pairingStorage.getPairing(forTopic: topic)?.peerMetadata
    }

    private func setPairingMetadata(rpcRequest: RPCRequest, topic: String) {
        guard var pairing = pairingStorage.getPairing(forTopic: topic),
              pairing.peerMetadata == nil,
              let peerMetadata = try? rpcRequest.params?.get(Auth_RequestParams.self).requester.metadata
        else { return }

        pairing.updatePeerMetadata(peerMetadata)
        pairingStorage.setPairing(pairing)
    }
}


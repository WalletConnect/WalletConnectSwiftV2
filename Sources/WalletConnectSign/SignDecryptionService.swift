import Foundation

public class SignDecryptionService {
    enum Errors: Error {
        case couldNotInitialiseDefaults
    }
    private let serializer: Serializing
    private let sessionStorage: WCSessionStorage

    public init(groupIdentifier: String) throws {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let kms = KeyManagementService(keychain: keychainStorage)
        self.serializer = Serializer(kms: kms, logger: ConsoleLogger(prefix: "🔐", loggingLevel: .off))
        guard let defaults = UserDefaults(suiteName: groupIdentifier) else {
            throw Errors.couldNotInitialiseDefaults
        }
        sessionStorage = SessionStorage(storage: SequenceStore<WCSession>(store: .init(defaults: defaults, identifier: SignStorageIdentifiers.sessions.rawValue)))
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> RPCRequest {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        return rpcRequest
    }

    public func getMetadata(topic: String) -> AppMetadata? {
        sessionStorage.getSession(forTopic: topic)?.peerParticipant.metadata
    }
}

import WalletConnectKMS

public class PushDecryptionService {
    enum Errors: Error {
        case malformedPushMessage
    }
    private let serializer: Serializing

    init(serializer: Serializing) {
        self.serializer = serializer
    }

    public init() {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: "group.com.walletconnect.sdk")
        let kms = KeyManagementService(keychain: keychainStorage)
        self.serializer = Serializer(kms: kms)
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> PushMessage {
        let rpcRequest: RPCRequest = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        guard let params = rpcRequest.params else { throw Errors.malformedPushMessage }
        return try params.get(PushMessage.self)
    }
}

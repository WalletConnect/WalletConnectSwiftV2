import Foundation

public class NotifyDecryptionService {
    enum Errors: Error {
        case malformedNotifyMessage
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

    public func decryptMessage(topic: String, ciphertext: String) throws -> NotifyMessage {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        guard let params = rpcRequest.params else { throw Errors.malformedNotifyMessage }
        return try params.get(NotifyMessage.self)
    }
}

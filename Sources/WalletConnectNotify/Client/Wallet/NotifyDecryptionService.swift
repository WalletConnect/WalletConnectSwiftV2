import Foundation

public class NotifyDecryptionService {
    enum Errors: Error {
        case malformedNotifyMessage
    }
    private let serializer: Serializing

    init(serializer: Serializing) {
        self.serializer = serializer
    }

    public init(groupIdentifier: String) {
        let keychainStorage = GroupKeychainStorage(serviceIdentifier: groupIdentifier)
        let kms = KeyManagementService(keychain: keychainStorage)
        self.serializer = Serializer(kms: kms, logger: ConsoleLogger(prefix: "🔐", loggingLevel: .off))
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> NotifyMessage {
        let (rpcRequest, _, _): (RPCRequest, String?, Data) = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        guard let params = rpcRequest.params else { throw Errors.malformedNotifyMessage }
        let wrapper = try params.get(NotifyMessagePayload.Wrapper.self)
        let (messagePayload, _) = try NotifyMessagePayload.decodeAndVerify(from: wrapper)
        return messagePayload.message
    }
}

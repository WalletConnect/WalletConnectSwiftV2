import WalletConnectKMS

public class PushDecryptionService {
    enum Errors: Error {
        case malformedPushMessage
    }
    private let serializer: Serializing

    public init(serializer: Serializing) {
        self.serializer = serializer
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> PushMessage {
        let rpcRequest: RPCRequest = try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
        guard let params = rpcRequest.params else { throw Errors.malformedPushMessage }
        let pushMessage = try params.get(PushMessage.self)
        return pushMessage
    }
}

import WalletConnectKMS

class DecryptionService {
    private let serializer: Serializing

    init(serializer: Serializing) {
        self.serializer = serializer
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> String {
        try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
    }
}

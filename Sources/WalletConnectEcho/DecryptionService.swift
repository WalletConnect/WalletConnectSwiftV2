import WalletConnectKMS

class DecryptionService {
    private let serializer: Serializing

    init(serializer: Serializing) {
        self.serializer = serializer
    }

    public func decryptMessage<T: Codable>(topic: String, ciphertext: String) throws -> T {
        try serializer.deserialize(topic: topic, encodedEnvelope: ciphertext)
    }
}

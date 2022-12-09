
import WalletConnectKMS

class DecryptionService {
    private let serialiser: Serializing

    init(serialiser: Serializing) {
        self.serialiser = serialiser
    }

    public func decryptMessage(topic: String, ciphertext: String) throws -> String {
        try serialiser.deserialize(topic: topic, encodedEnvelope: ciphertext)
    }
}

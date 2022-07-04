import Foundation

protocol DIDKeyFactory {
    func make(pubKey: Data, prefix: Bool) -> String
}

/// A DID Method for Static Cryptographic Keys
/// did-key-format := did:key:MULTIBASE(base58-btc, MULTICODEC(public-key-type, raw-public-key-bytes))
struct ED25519DIDKeyFactory: DIDKeyFactory {
    private let DID_DELIMITER = ":"
    private let DID_PREFIX = "did"
    private let DID_METHOD = "key"
    private let MULTICODEC_ED25519_HEADER: [UInt8] = [0xed, 0x01]
    private let MULTICODEC_ED25519_BASE = "z"

    func make(pubKey: Data, prefix: Bool) -> String {
        let multibase = multibase(pubKey: pubKey)

        guard prefix else { return multibase }

        return [
            DID_PREFIX,
            DID_METHOD,
            multibase
        ].joined(separator: DID_DELIMITER)
    }

    private func multibase(pubKey: Data) -> String {
        let multicodec = Data(MULTICODEC_ED25519_HEADER) + pubKey
        return MULTICODEC_ED25519_BASE + Base58.encode(multicodec)
    }
}

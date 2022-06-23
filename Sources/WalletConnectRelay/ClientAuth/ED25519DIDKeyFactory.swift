import Foundation

protocol ED25519DIDKeyFactory {
    func make(pubKey: Data) -> String
}

/// did-key-format := did:key:MULTIBASE(base58-btc, MULTICODEC(public-key-type, raw-public-key-bytes))
struct ED25519DIDKeyFactoryImpl: ED25519DIDKeyFactory {
    private static let DID_DELIMITER = ":"
    private static let DID_PREFIX = "did"
    private static let DID_METHOD = "key"
    private static let MULTICODEC_ED25519_HEADER = "K36"
    private static let MULTICODEC_ED25519_ENCODING = "base58btc"
    private static let MULTICODEC_ED25519_BASE = "z"

    func make(pubKey: Data) -> String {
        fatalError("not implemented")

        let multicodec = multicodec()

        let multibase = multibase(multicodec: multicodec)

        return [Self.DID_PREFIX, Self.DID_METHOD, multibase].joined(separator: Self.DID_DELIMITER)
    }

    private func multibase(multicodec: String) -> String {
        fatalError("not implemented")
    }

    private func multicodec() -> String {
        fatalError("not implemented")
    }
}

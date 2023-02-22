import Foundation

/// A DID Method for Static Cryptographic Keys
/// did-key-format := did:key:MULTIBASE(base58-btc, MULTICODEC(public-key-type, raw-public-key-bytes))
struct DIDKeyFactory {

    enum Errors: Error {
        case invalidDIDPKH
    }

    private let DID_DELIMITER = ":"
    private let DID_PREFIX = "did"
    private let DID_METHOD = "key"
    private let MULTICODEC_BASE = "z"

    init() { }

    func make(pubKey: Data, variant: DIDKeyVariant, prefix: Bool) -> String {
        let multibase = multibase(pubKey: pubKey, variant: variant)

        guard prefix else { return multibase }

        return [
            DID_PREFIX,
            DID_METHOD,
            multibase
        ].joined(separator: DID_DELIMITER)
    }

    func decode(key: String) throws -> Data {
        guard let multibase = key.components(separatedBy: ":").last
        else { throw Errors.invalidDIDPKH }

        let encoded = String(multibase.dropFirst())
        let multicodec = Base58.decode(encoded)
        return Data(multicodec.dropFirst(2))
    }

    private func multibase(pubKey: Data, variant: DIDKeyVariant) -> String {
        let multicodec = Data(variant.header) + pubKey
        return MULTICODEC_BASE + Base58.encode(multicodec)
    }
}

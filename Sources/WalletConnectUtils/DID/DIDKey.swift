import Foundation

public struct DIDKey {

    enum Errors: Error {
        case invalidDIDPKH
    }

    private static let didPrefix: String = "did:key"

    private let rawData: Data

    public init(did: String) throws {
        guard did.starts(with: DIDKey.didPrefix)
        else { throw Errors.invalidDIDPKH }

        guard let string = did.components(separatedBy: DIDKey.didPrefix + ":").last
        else { throw Errors.invalidDIDPKH }

        self.rawData = Base58.decode(string)
    }

    public init(rawData: Data) {
        self.rawData = rawData
    }

    public var hexString: String {
        return rawData.toHexString()
    }

    public func did(prefix: Bool) -> String {
        return ED25519DIDKeyFactory().make(pubKey: rawData, prefix: prefix)
    }
}

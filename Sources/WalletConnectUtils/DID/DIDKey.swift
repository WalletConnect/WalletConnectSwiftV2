import Foundation

public struct DIDKey {

    private let rawData: Data

    public init(did: String) throws {
        self.rawData = try ED25519DIDKeyFactory().decode(key: did)
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

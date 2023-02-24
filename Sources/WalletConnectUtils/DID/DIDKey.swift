import Foundation

public struct DIDKey {

    public let rawData: Data

    public init(did: String) throws {
        self.rawData = try DIDKeyFactory().decode(key: did)
    }

    public init(rawData: Data) {
        self.rawData = rawData
    }

    public var hexString: String {
        return rawData.toHexString()
    }

    public func did(prefix: Bool, variant: DIDKeyVariant) -> String {
        return DIDKeyFactory().make(pubKey: rawData, variant: variant, prefix: prefix)
    }
}

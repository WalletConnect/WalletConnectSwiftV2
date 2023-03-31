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

    public func multibase(variant: DIDKeyVariant) -> String {
        return DIDKeyFactory().make(pubKey: rawData, variant: variant, prefix: false)
    }

    public func did(variant: DIDKeyVariant) -> String {
        return DIDKeyFactory().make(pubKey: rawData, variant: variant, prefix: true)
    }
}

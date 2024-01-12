import Foundation

public struct RelayProtocolOptions: Codable, Equatable {
    public let `protocol`: String
    public let data: String?

    public init(protocol: String, data: String?) {
        self.protocol = `protocol`
        self.data = data
    }
}

#if DEBUG
public extension RelayProtocolOptions {
    static func stub() -> RelayProtocolOptions {
        RelayProtocolOptions(protocol: "", data: nil)
    }
}
#endif

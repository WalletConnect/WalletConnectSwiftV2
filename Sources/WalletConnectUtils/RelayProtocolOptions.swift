import Foundation

public struct RelayProtocolOptions: Codable, Equatable {
    public let `protocol`: String
    public let data: String?

    public init(protocol: String, data: String?) {
        self.protocol = `protocol`
        self.data = data
    }
}

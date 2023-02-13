import Foundation

public struct CacaoHeader: Codable, Equatable {
    public let t: String

    public init(t: String) {
        self.t = t
    }
}

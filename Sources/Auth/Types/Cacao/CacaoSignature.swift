import Foundation

public struct CacaoSignature: Codable, Equatable {
    public let t: String
    public let s: String
    public let m: String? = nil
}

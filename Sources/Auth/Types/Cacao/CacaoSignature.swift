import Foundation

public struct CacaoSignature: Codable, Equatable {
    let t: String
    let s: String
    let m: String?

    public init(t: String, s: String, m: String? = nil) {
        self.t = t
        self.s = s
        self.m = m
    }
}

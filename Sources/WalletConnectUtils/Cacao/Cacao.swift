import Foundation

/// CAIP-74 Cacao object
///
/// specs at:  https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-74.md
public struct Cacao: Codable, Equatable {
    public let h: CacaoHeader
    public let p: CacaoPayload
    public let s: CacaoSignature

    public init(h: CacaoHeader, p: CacaoPayload, s: CacaoSignature) {
        self.h = h
        self.p = p
        self.s = s
    }
}

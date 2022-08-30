import Foundation

/// CAIP-74 Cacao object
///
/// specs at:  https://github.com/ChainAgnostic/CAIPs/blob/master/CAIPs/caip-74.md
public struct Cacao: Codable, Equatable {
    let header: CacaoHeader
    let payload: CacaoPayload
    let signature: CacaoSignature
}

import Foundation

struct Cacao: Codable, Equatable {
    let header: CacaoHeader
    let payload: CacaoPayload
    let signature: CacaoSignature
}

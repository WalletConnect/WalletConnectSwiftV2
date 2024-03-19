import Foundation

public struct AuthRespondParams: Equatable {
    let id: RPCID
    let signature: CacaoSignature

    public init(id: RPCID, signature: CacaoSignature) {
        self.id = id
        self.signature = signature
    }
}

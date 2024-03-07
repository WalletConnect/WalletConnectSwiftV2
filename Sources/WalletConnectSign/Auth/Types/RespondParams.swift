import Foundation

public struct RespondParams: Equatable {
    let id: RPCID
    let signature: CacaoSignature

    public init(id: RPCID, signature: CacaoSignature) {
        self.id = id
        self.signature = signature
    }
}

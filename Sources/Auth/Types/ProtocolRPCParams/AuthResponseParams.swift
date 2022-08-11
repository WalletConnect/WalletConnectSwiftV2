import Foundation
import WalletConnectUtils

struct AuthResponseParams: Codable, Equatable {
    let header: CacaoHeader
    let payload: CacaoPayload
    let signature: CacaoSignature

    static var tag: Int {
        return 3001
    }
}

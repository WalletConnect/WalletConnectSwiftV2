import Foundation
import WalletConnectUtils

/// wc_authRequest RPC method respond param
struct AuthResponseParams: Codable, Equatable {
    let header: CacaoHeader
    let payload: CacaoPayload
    let signature: CacaoSignature
}

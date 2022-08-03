import Foundation
import WalletConnectUtils

protocol CacaoFormatting {
    func format(_ request: AuthRequestParams, _ signature: CacaoSignature, _ issuer: Account) -> Cacao
}

class CacaoFormatter: CacaoFormatting {
    func format(_ request: AuthRequestParams, _ signature: CacaoSignature, _ issuer: Account) -> Cacao {
        fatalError("not implemented")
    }
}

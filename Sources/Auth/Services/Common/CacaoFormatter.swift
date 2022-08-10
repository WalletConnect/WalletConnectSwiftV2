import Foundation
import WalletConnectUtils

protocol CacaoFormatting {
    func format(_ request: AuthRequestParams, _ signature: CacaoSignature, _ account: Account) -> Cacao
}

class CacaoFormatter: CacaoFormatting {
    func format(_ request: AuthRequestParams, _ signature: CacaoSignature, _ account: Account) -> Cacao {
        fatalError("not implemented")
    }
}

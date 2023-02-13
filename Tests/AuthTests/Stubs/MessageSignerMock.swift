import Foundation
import Auth

struct MessageSignerMock: CacaoMessageSigner {
    func sign(message: String, privateKey: Data, type: WalletConnectUtils.CacaoSignatureType) throws -> WalletConnectUtils.CacaoSignature {
        return CacaoSignature(t: .eip191, s: "")
    }

    func verify(signature: CacaoSignature,
        message: String,
        address: String,
        chainId: String
    ) async throws {

    }

    func sign(payload: CacaoPayload,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {
        return CacaoSignature(t: .eip191, s: "")
    }
}

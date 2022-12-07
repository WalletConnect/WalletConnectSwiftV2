import Foundation
import Auth

struct MessageSignerMock: AuthMessageSigner {

    func verify(signature: CacaoSignature,
        message: String,
        address: String,
        chainId: String
    ) async throws {

    }

    func sign(payload: AuthPayload,
        address: String,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {
        return CacaoSignature(t: .eip191, s: "")
    }
}

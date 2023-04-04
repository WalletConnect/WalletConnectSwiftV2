import Foundation

public struct MessageVerifier {

    enum Errors: Error {
        case utf8EncodingFailed
    }

    private let eip191Verifier: EIP191Verifier
    private let eip1271Verifier: EIP1271Verifier

    init(eip191Verifier: EIP191Verifier, eip1271Verifier: EIP1271Verifier) {
        self.eip191Verifier = eip191Verifier
        self.eip1271Verifier = eip1271Verifier
    }

    public func verify(signature: CacaoSignature,
        message: String,
        address: String,
        chainId: String
    ) async throws {

        guard let messageData = message.data(using: .utf8) else {
            throw Errors.utf8EncodingFailed
        }

        let signatureData = Data(hex: signature.s)

        switch signature.t {
        case .eip191:
            return try await eip191Verifier.verify(
                signature: signatureData,
                message: messageData.prefixed,
                address: address
            )
        case .eip1271:
            return try await eip1271Verifier.verify(
                signature: signatureData,
                message: messageData.prefixed,
                address: address,
                chainId: chainId
            )
        }
    }
}

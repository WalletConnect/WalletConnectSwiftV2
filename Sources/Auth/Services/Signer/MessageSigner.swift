import Foundation

protocol MessageSignatureVerifying {
    func verify(signature: CacaoSignature, message: String, address: String) async throws
}

protocol MessageSigning {
    func sign(message: String, privateKey: Data) throws -> CacaoSignature
}

public struct MessageSigner: MessageSignatureVerifying, MessageSigning {

    enum Errors: Error {
        case utf8EncodingFailed
    }

    private let signer: Signer
    private let eip191Verifier: EIP191Verifier
    private let eip1271Verifier: EIP1271Verifier

    init(signer: Signer, eip191Verifier: EIP191Verifier, eip1271Verifier: EIP1271Verifier) {
        self.signer = signer
        self.eip191Verifier = eip191Verifier
        self.eip1271Verifier = eip1271Verifier
    }

    public func sign(message: String, privateKey: Data) throws -> CacaoSignature {
        guard let messageData = message.data(using: .utf8) else { throw Errors.utf8EncodingFailed }
        let signature = try signer.sign(message: prefixed(messageData), with: privateKey)
        let prefixedHexSignature = "0x" + signature.toHexString()
        return CacaoSignature(t: .eip191, s: prefixedHexSignature)
    }

    public func verify(signature: CacaoSignature, message: String, address: String) async throws {
        guard let messageData = message.data(using: .utf8) else {
            throw Errors.utf8EncodingFailed
        }

        let signatureData = Data(hex: signature.s)

        switch signature.t {
        case .eip191:
            return try await eip191Verifier.verify(
                signature: signatureData,
                message: prefixed(messageData),
                address: address
            )
        case .eip1271:
            return try await eip191Verifier.verify(
                signature: signatureData,
                message: prefixed(messageData),
                address: address
            )
        }
    }
}

private extension MessageSigner {

    private func prefixed(_ message: Data) -> Data {
        return "\u{19}Ethereum Signed Message:\n\(message.count)"
            .data(using: .utf8)! + message
    }
}

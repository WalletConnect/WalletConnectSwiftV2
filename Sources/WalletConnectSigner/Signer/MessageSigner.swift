import Foundation

public protocol MessageSignatureVerifying {
    func verify(signature: CacaoSignature,
        message: String,
        address: String,
        chainId: String
    ) async throws
}

public protocol MessageSigning {
    func sign(message: String,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature

    func sign(payload: CacaoPayload,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature
}

// TODO: Fix naming
public typealias CacaoMessageSigner = MessageSignatureVerifying & MessageSigning

struct MessageSigner: CacaoMessageSigner {

    enum Errors: Error {
        case utf8EncodingFailed
    }

    private let signer: EthereumSigner
    private let eip191Verifier: EIP191Verifier
    private let eip1271Verifier: EIP1271Verifier
    private let messageFormatter: SIWECacaoFormatting

    init(signer: EthereumSigner, eip191Verifier: EIP191Verifier, eip1271Verifier: EIP1271Verifier, messageFormatter: SIWECacaoFormatting) {
        self.signer = signer
        self.eip191Verifier = eip191Verifier
        self.eip1271Verifier = eip1271Verifier
        self.messageFormatter = messageFormatter
    }

    func sign(payload: CacaoPayload,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {

        let message = try messageFormatter.formatMessage(from: payload)
        return try sign(message: message, privateKey: privateKey, type: type)
    }

    func sign(message: String,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {

        guard let messageData = message.data(using: .utf8)else {
            throw Errors.utf8EncodingFailed
        }

        let signature = try signer.sign(message: prefixed(messageData), with: privateKey)
        return CacaoSignature(t: type, s: signature.hex())
    }

    func verify(signature: CacaoSignature,
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
                message: prefixed(messageData),
                address: address
            )
        case .eip1271:
            return try await eip1271Verifier.verify(
                signature: signatureData,
                message: prefixed(messageData),
                address: address,
                chainId: chainId
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

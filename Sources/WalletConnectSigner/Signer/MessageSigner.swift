import Foundation

public struct MessageSigner {

    enum Errors: Error {
        case utf8EncodingFailed
    }

    private let signer: EthereumSigner
    private let messageFormatter: SIWECacaoFormatting

    init(signer: EthereumSigner, messageFormatter: SIWECacaoFormatting) {
        self.signer = signer
        self.messageFormatter = messageFormatter
    }

    public func sign(payload: CacaoPayload,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {

        let message = try messageFormatter.formatMessage(from: payload)
        return try sign(message: message, privateKey: privateKey, type: type)
    }

    public func sign(message: String,
        privateKey: Data,
        type: CacaoSignatureType
    ) throws -> CacaoSignature {

        guard let messageData = message.data(using: .utf8)else {
            throw Errors.utf8EncodingFailed
        }

        let signature = try signer.sign(message: messageData.prefixed, with: privateKey)
        return CacaoSignature(t: type, s: signature.hex())
    }
}

import Foundation

protocol CacaoSignerKeystore {
    var privateKey: Data { get async }
}

actor CacaoSigner {
    enum Errors: Error {
        case signatureCorrupted
        case signatureValidationFailed
    }

    private let signer: Signer
    private let keystore: CacaoSignerKeystore

    init(signer: Signer, keystore: CacaoSignerKeystore) {
        self.signer = signer
        self.keystore = keystore
    }

    func sign(payload: CacaoPayload) async throws -> CacaoSignature {
        let message = try JSONEncoder().encode(payload)
        let signature = try await signer.sign(message: message, with: keystore.privateKey)
        return CacaoSignature(t: "eip191", s: signature.toHexString(), m: String())
    }

    func verify(signature: CacaoSignature, payload: CacaoPayload) async throws {
        let message = try JSONEncoder().encode(payload)
        let address = try SignerAddress.from(iss: payload.iss)

        guard let signature = signature.s.data(using: .utf8)
        else { throw Errors.signatureCorrupted }

        guard try signer.isValid(signature: signature, message: message, address: address)
        else { throw Errors.signatureValidationFailed }
    }
}

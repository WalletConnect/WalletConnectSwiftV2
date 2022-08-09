import Foundation

protocol CacaoSignatureVerifying {
    func verifySignature(_ cacao: Cacao) throws
}

struct CacaoSigner: CacaoSignatureVerifying {

    enum Errors: Error {
        case signatureValidationFailed
    }

    private let signer: Signer

    init(signer: Signer) {
        self.signer = signer
    }

    func sign(payload: CacaoPayload, privateKey: Data) throws -> CacaoSignature {
        let message = try JSONEncoder().encode(payload) // TODO: SIWE encoding
        let signature = try signer.sign(message: message, with: privateKey)
        return CacaoSignature(t: "eip191", s: signature.toHexString(), m: String()) 
    }

    func verifySignature(_ cacao: Cacao) throws {
        let sig = Data(hex: cacao.signature.s)
        let message = try JSONEncoder().encode(cacao.payload)
        let address = try DIDPKH(iss: cacao.payload.iss).account.address
        guard try signer.isValid(signature: sig, message: message, address: address)
        else { throw Errors.signatureValidationFailed }
    }
}

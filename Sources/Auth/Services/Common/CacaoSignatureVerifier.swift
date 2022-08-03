import Foundation

protocol CacaoSignatureVerifying {
    func verifySignature(_ cacao: Cacao) throws
}

class CacaoSignatureVerifier: CacaoSignatureVerifying {
    enum Errors: Error {
        case signatureInvalid
    }

    func verifySignature(_ cacao: Cacao) throws {
        fatalError("not implemented")
    }
}


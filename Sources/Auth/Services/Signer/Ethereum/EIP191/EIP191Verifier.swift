import Foundation

actor EIP191Verifier {

    let signer: EthereumSigner

    init(signer: EthereumSigner) {
        self.signer = signer
    }

    func verify(signature: Data, message: Data, address: String) async throws {
        let sig = EthereumSignature(serialized: signature)
        let publicKey = try signer.recover(signature: sig, message: message)
        try verifyPublicKey(publicKey, address: address)
    }

    private func verifyPublicKey(_ publicKey: EthereumPubKey, address: String) throws {
        guard publicKey.hex() == address.lowercased() else {
            throw Errors.invalidSignature
        }
    }
}

extension EIP191Verifier {
    enum Errors: Error {
        case invalidSignature
    }
}

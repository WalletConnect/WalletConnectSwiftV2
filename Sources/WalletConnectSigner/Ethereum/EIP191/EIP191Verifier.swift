import Foundation

actor EIP191Verifier {

    let crypto: CryptoProvider

    init(crypto: CryptoProvider) {
        self.crypto = crypto
    }

    func verify(signature: Data, message: Data, address: String) async throws {
        let sig = EthereumSignature(serialized: signature)
        let publicKey = try crypto.recoverPubKey(signature: sig, message: message)
        try verifyPublicKey(publicKey, address: address)
    }

    private func verifyPublicKey(_ publicKey: Data, address: String) throws {
        let recovered = "0x" + crypto.keccak256(publicKey)
            .suffix(20)
            .toHexString()

        guard recovered == address.lowercased() else {
            throw Errors.invalidSignature
        }
    }
}

extension EIP191Verifier {
    enum Errors: Error {
        case invalidSignature
    }
}

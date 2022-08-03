import Foundation
import WalletConnectUtils

struct SignerAddress {

    static let didPrefix: String = "did:pkh"
    static let lenght: Int = 20

    enum Errors: Error {
        case invalidPublicKey
        case invalidDidPkh
    }

    static func from(iss: String) throws -> String {
        guard iss.starts(with: didPrefix)
        else { throw Errors.invalidDidPkh }

        guard let string = iss.components(separatedBy: didPrefix + ":").last, let account = Account(string)
        else { throw Errors.invalidDidPkh }

        return account.address.lowercased()
    }

    static func from(publicKey: Data) throws -> String {
        guard publicKey.count >= lenght
        else { throw Errors.invalidPublicKey }

        return "0x" + publicKey.keccak256.suffix(SignerAddress.lenght).toHexString()
    }
}

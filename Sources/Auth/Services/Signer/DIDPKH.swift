import Foundation
import WalletConnectUtils

struct DIDPKH {
    static let didPrefix: String = "did:pkh"

    enum Errors: Error {
        case invalidDIDPKH
        case invalidAccount
    }

    let account: Account
    let iss: String

    init(iss: String) throws {
        guard iss.starts(with: DIDPKH.didPrefix)
        else { throw Errors.invalidDIDPKH }

        guard let string = iss.components(separatedBy: DIDPKH.didPrefix + ":").last
        else { throw Errors.invalidDIDPKH }

        guard let account = Account(string)
        else { throw Errors.invalidAccount }

        self.iss = iss
        self.account = account
    }

    init(account: Account) {
        self.iss = "\(DIDPKH.didPrefix):\(account.absoluteString)"
        self.account = account
    }
}

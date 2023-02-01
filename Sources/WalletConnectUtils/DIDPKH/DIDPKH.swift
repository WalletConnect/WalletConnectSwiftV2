import Foundation

public struct DIDPKH {

    private static let didPrefix: String = "did:pkh"

    enum Errors: Error {
        case invalidDIDPKH
        case invalidAccount
    }

    public let account: Account
    public let iss: String

    public init(iss: String) throws {
        guard iss.starts(with: DIDPKH.didPrefix)
        else { throw Errors.invalidDIDPKH }

        guard let string = iss.components(separatedBy: DIDPKH.didPrefix + ":").last
        else { throw Errors.invalidDIDPKH }

        guard let account = Account(string)
        else { throw Errors.invalidAccount }

        self.iss = iss
        self.account = account
    }

    public init(account: Account) {
        self.iss = "\(DIDPKH.didPrefix):\(account.absoluteString)"
        self.account = account
    }
}

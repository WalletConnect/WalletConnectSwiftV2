import Foundation

public struct DIDPKH {

    private static let didPrefix: String = "did:pkh"

    enum Errors: Error {
        case invalidDIDPKH
        case invalidAccount
    }

    public let account: Account
    public let string: String

    public init(did: String) throws {
        guard did.starts(with: DIDPKH.didPrefix)
        else { throw Errors.invalidDIDPKH }

        guard let string = did.components(separatedBy: DIDPKH.didPrefix + ":").last
        else { throw Errors.invalidDIDPKH }

        guard let account = Account(string)
        else { throw Errors.invalidAccount }

        self.string = string
        self.account = account
    }

    public init(account: Account) {
        self.string = "\(DIDPKH.didPrefix):\(account.absoluteString)"
        self.account = account
    }
}

extension Account {

    public init(DIDPKHString: String) throws {
        self = try DIDPKH(did: DIDPKHString).account
    }

    public var did: String {
        return DIDPKH(account: self).string
    }
}

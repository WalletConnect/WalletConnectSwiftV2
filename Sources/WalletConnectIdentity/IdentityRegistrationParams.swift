import Foundation

public struct IdentityRegistrationParams {
    public let message: String
    public let payload: CacaoPayload
    public let privateIdentityKey: SigningPrivateKey

    public var account: Account {
        get throws { try Account(DIDPKHString: payload.iss) }
    }
}

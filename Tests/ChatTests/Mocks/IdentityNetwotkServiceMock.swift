import Foundation
@testable import WalletConnectChat
@testable import WalletConnectIdentity

final class IdentityNetwotkServiceMock: IdentityNetworking {

    private(set) var callRegisterIdentity: Bool = false
    private(set) var callRemoveIdentity: Bool = false
    private(set) var callRegisterInvite: Bool = false
    private(set) var callRemoveInvite: Bool = false

    private let cacao: Cacao
    private let inviteKey: String

    init(cacao: Cacao, inviteKey: String) {
        self.cacao = cacao
        self.inviteKey = inviteKey
    }

    func registerIdentity(cacao: WalletConnectUtils.Cacao) async throws {
        callRegisterIdentity = true
    }

    func resolveIdentity(publicKey: String) async throws -> WalletConnectUtils.Cacao {
        return cacao
    }

    func removeIdentity(cacao: WalletConnectUtils.Cacao) async throws {
        callRemoveIdentity = true
    }

    func registerInvite(idAuth: String) async throws {
        callRegisterInvite = true
    }

    func resolveInvite(account: String) async throws -> String {
        return inviteKey
    }

    func removeInvite(idAuth: String) async throws {
        callRemoveInvite = true
    }
}

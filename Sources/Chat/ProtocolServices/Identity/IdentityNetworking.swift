import Foundation

protocol IdentityNetworking {
    func registerIdentity(cacao: Cacao) async throws
    func resolveIdentity(publicKey: String) async throws -> Cacao
    func removeIdentity(cacao: Cacao) async throws
    func registerInvite(idAuth: String) async throws
    func resolveInvite(account: String) async throws -> String
    func removeInvite(idAuth: String) async throws
}

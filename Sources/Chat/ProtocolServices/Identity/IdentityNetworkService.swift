import Foundation

actor IdentityNetworkService {

    private let accountService: AccountService
    private let httpService: HTTPClient

    init(accountService: AccountService, httpService: HTTPClient) {
        self.accountService = accountService
        self.httpService = httpService
    }

    // MARK: - IdentityKey

    func registerIdentity(cacao: Cacao) async throws {
        let api = IdentityKeyAPI.registerIdentity(cacao: cacao)
        try await httpService.request(service: api)
    }

    func resolveIdentity(publicKey: String) async throws -> Cacao {
        let api = IdentityKeyAPI.resolveIdentity(publicKey: publicKey)
        let response = try await httpService.request(ResolveIdentityResponse.self, at: api)
        return response.value.cacao
    }

    func removeIdentity(cacao: Cacao) async throws {
        let api = IdentityKeyAPI.removeIdentity(cacao: cacao)
        try await httpService.request(service: api)
    }

    // MARK: - InviteKey

    func registerInvite(idAuth: String) async throws {
        let api = IdentityKeyAPI.registerInvite(idAuth: idAuth)
        try await httpService.request(service: api)
    }

    func resolveInvite(account: String) async throws -> String {
        let api = IdentityKeyAPI.resolveInvite(account: account)
        let response = try await httpService.request(ResolveInviteResponse.self, at: api)
        return response.inviteKey
    }

    func removeInvite(idAuth: String) async throws {
        let api = IdentityKeyAPI.removeInvite(idAuth: idAuth)
        try await httpService.request(service: api)
    }
}

private extension IdentityNetworkService {

    struct ResolveIdentityResponse: Codable {
        struct Value: Codable {
            let cacao: Cacao
        }
        let value: Value
    }

    struct ResolveInviteResponse: Codable {
        let inviteKey: String
    }
}

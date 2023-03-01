import Foundation

actor IdentityNetworkService: IdentityNetworking {

    private let httpService: HTTPClient

    init(httpService: HTTPClient) {
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
        return response.value.inviteKey
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
        struct Value: Codable {
            let inviteKey: String
        }
        let value: Value
    }
}

import Foundation

actor NotifyConfigProvider {

    private let projectId: String

    init(projectId: String) {
        self.projectId = projectId
    }

    func resolveNotifyConfig(appDomain: String) async throws -> NotifyConfig {
        let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
        let request = NotifyConfigAPI.notifyDApps(projectId: projectId, appDomain: appDomain)
        let response = try await httpClient.request(NotifyConfigResponse.self, at: request)
        return response.data
    }
}

private extension NotifyConfigProvider {

    struct NotifyConfigResponse: Codable {
        let data: NotifyConfig
    }
}

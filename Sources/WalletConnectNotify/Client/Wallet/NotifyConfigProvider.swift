import Foundation

actor NotifyConfigProvider {

    private let projectId: String

    private var cache: [String: NotifyConfig] = [:]

    init(projectId: String) {
        self.projectId = projectId
    }

    func resolveNotifyConfig(appDomain: String) async -> NotifyConfig {
        if let config = cache[appDomain] {
            return config
        }

        do {
            let httpClient = HTTPNetworkClient(host: "explorer-api.walletconnect.com")
            let request = NotifyConfigAPI.notifyDApps(projectId: projectId, appDomain: appDomain)
            let response = try await httpClient.request(NotifyConfigResponse.self, at: request)
            let config = response.data
            cache[appDomain] = config
            return config
        } catch {
            return emptyConfig(appDomain: appDomain)
        }
    }
}

private extension NotifyConfigProvider {

    struct NotifyConfigResponse: Codable {
        let data: NotifyConfig
    }

    func emptyConfig(appDomain: String) -> NotifyConfig {
        return NotifyConfig(
            id: UUID().uuidString,
            name: appDomain,
            homepage: "https://\(appDomain)",
            description: "", 
            dapp_url: "https://\(appDomain)",
            image_url: nil,
            notificationTypes: []
        )
    }
}

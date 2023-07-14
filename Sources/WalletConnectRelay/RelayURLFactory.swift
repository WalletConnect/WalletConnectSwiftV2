import Foundation

struct RelayUrlFactory {
    private let relayHost: String
    private let projectId: String
    private let socketAuthenticator: ClientIdAuthenticating

    init(
        relayHost: String,
        projectId: String,
        socketAuthenticator: ClientIdAuthenticating
    ) {
        self.relayHost = relayHost
        self.projectId = projectId
        self.socketAuthenticator = socketAuthenticator
    }

    func create() -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = relayHost
        components.queryItems = [
            URLQueryItem(name: "projectId", value: projectId)
        ]
        do {
            let authToken = try socketAuthenticator.createAuthToken()
            components.queryItems?.append(URLQueryItem(name: "auth", value: authToken))
        } catch {
            // TODO: Handle token creation errors
            print("Auth token creation error: \(error.localizedDescription)")
        }
        return components.url!
    }
}

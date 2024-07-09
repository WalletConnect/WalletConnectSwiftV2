import Foundation

class RelayUrlFactory {
    private let relayHost: String
    private let projectId: String
    private let socketAuthenticator: ClientIdAuthenticating
    /// The property is used to determine whether relay.walletconnect.org will be used
    /// in case relay.walletconnect.com doesn't respond for some reason (most likely due to being blocked in the user's location).
    private var fallback: Bool = false

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
            let authToken = try socketAuthenticator.createAuthToken(url: "wss://" + relayHost)
            components.queryItems?.append(URLQueryItem(name: "auth", value: authToken))
        } catch {
            // TODO: Handle token creation errors
            print("Auth token creation error: \(error.localizedDescription)")
        }
        return components.url!
    }
}

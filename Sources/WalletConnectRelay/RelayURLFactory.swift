import Foundation

struct RelayUrlFactory {
    private let socketAuthenticator: SocketAuthenticating

    init(socketAuthenticator: SocketAuthenticating) {
        self.socketAuthenticator = socketAuthenticator
    }

    func create(host: String, projectId: String) -> URL {
        var components = URLComponents()
        components.scheme = "wss"
        components.host = host
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

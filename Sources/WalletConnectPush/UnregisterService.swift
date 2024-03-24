import Foundation

actor UnregisterService {
    private let httpClient: HTTPClient
    private let projectId: String
    private let logger: ConsoleLogging
    private let environment: APNSEnvironment
    private let pushAuthenticator: PushAuthenticating
    private let clientIdStorage: ClientIdStoring
    private let pushHost: String

    init(httpClient: HTTPClient,
         projectId: String,
         clientIdStorage: ClientIdStoring,
         pushAuthenticator: PushAuthenticating,
         logger: ConsoleLogging,
         pushHost: String,
         environment: APNSEnvironment) {
        self.httpClient = httpClient
        self.clientIdStorage = clientIdStorage
        self.pushAuthenticator = pushAuthenticator
        self.projectId = projectId
        self.logger = logger
        self.pushHost = pushHost
        self.environment = environment
    }

    func unregister() async throws {
            let pushAuthToken = try pushAuthenticator.createAuthToken()
            let clientId = try clientIdStorage.getClientId()

            guard let url = URL(string: "https://\(pushHost)/\(projectId)/clients/\(clientId)") else {
                logger.error("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.addValue("\(pushAuthToken)", forHTTPHeaderField: "Authorization")

            do {
                let (_, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    logger.error("Failed to unregister from Push Server")
                    throw NSError(domain: "UnregisterService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to unregister"])
                }

                logger.debug("Successfully unregistered from Push Server")
            } catch {
                logger.error("Push Server unregistration error: \(error.localizedDescription)")
                throw error
            }
        }
}

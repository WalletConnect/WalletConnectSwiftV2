import Foundation
import WalletConnectNetworking

actor EchoRegisterService {
    private let httpClient: HTTPClient
    private let projectId: String
    private let clientId: String
    private let logger: ConsoleLogging
    private let environment: APNSEnvironment
    // DID method specific identifier
    private var clientIdMutlibase: String {
        return clientId.replacingOccurrences(of: "did:key:", with: "")
    }

    enum Errors: Error {
        case registrationFailed
    }

    init(httpClient: HTTPClient,
         projectId: String,
         clientId: String,
         logger: ConsoleLogging,
         environment: APNSEnvironment) {
        self.httpClient = httpClient
        self.clientId = clientId
        self.projectId = projectId
        self.logger = logger
        self.environment = environment
    }

    func register(deviceToken: Data) async throws {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        logger.debug("APNS device token: \(token)")
        let response = try await httpClient.request(
            EchoResponse.self,
            at: EchoAPI.register(clientId: clientIdMutlibase, token: token, projectId: projectId, environment: environment)
        )
        guard response.status == .success else {
            throw Errors.registrationFailed
        }
        logger.debug("Successfully registered at Echo Server")
    }

#if DEBUG
    public func register(deviceToken: String) async throws {
        let response = try await httpClient.request(
            EchoResponse.self,
            at: EchoAPI.register(clientId: clientIdMutlibase, token: deviceToken, projectId: projectId, environment: environment)
        )
        guard response.status == .success else {
            throw Errors.registrationFailed
        }
        logger.debug("Successfully registered at Echo Server")
    }
#endif
}

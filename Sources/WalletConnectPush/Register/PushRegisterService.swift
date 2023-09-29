import Foundation

actor PushRegisterService {
    private let httpClient: HTTPClient
    private let projectId: String
    private let logger: ConsoleLogging
    private let environment: APNSEnvironment
    private let pushAuthenticator: PushAuthenticating
    private let clientIdStorage: ClientIdStoring
    /// The property is used to determine whether echo.walletconnect.org will be used
    /// in case echo.walletconnect.com doesn't respond for some reason (most likely due to being blocked in the user's location).
    private var fallback = false
    
    enum Errors: Error {
        case registrationFailed
    }

    init(httpClient: HTTPClient,
         projectId: String,
         clientIdStorage: ClientIdStoring,
         pushAuthenticator: PushAuthenticating,
         logger: ConsoleLogging,
         environment: APNSEnvironment) {
        self.httpClient = httpClient
        self.clientIdStorage = clientIdStorage
        self.pushAuthenticator = pushAuthenticator
        self.projectId = projectId
        self.logger = logger
        self.environment = environment
    }

    func register(deviceToken: Data) async throws {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        let pushAuthToken = try pushAuthenticator.createAuthToken()
        let clientId = try clientIdStorage.getClientId()
        let clientIdMutlibase = try DIDKey(did: clientId).multibase(variant: .ED25519)
        logger.debug("APNS device token: \(token)")
        
        do {
            let response = try await httpClient.request(
                PushResponse.self,
                at: PushAPI.register(clientId: clientIdMutlibase, token: token, projectId: projectId, environment: environment, auth: pushAuthToken)
            )
            guard response.status == .success else {
                throw Errors.registrationFailed
            }
            logger.debug("Successfully registered at Push Server")
        } catch {
            if (error as? HTTPError) == .couldNotConnect && !fallback {
                logger.debug("Trying fallback")
                fallback = true
                await echoHostFallback()
                try await register(deviceToken: deviceToken)
            }
            logger.debug("Push Server registration error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func echoHostFallback() async {
        await httpClient.updateHost(host: "echo.walletconnect.org")
    }

#if DEBUG
    public func register(deviceToken: String) async throws {
        let pushAuthToken = try pushAuthenticator.createAuthToken()
        let clientId = try clientIdStorage.getClientId()
        let clientIdMutlibase = try DIDKey(did: clientId).multibase(variant: .ED25519)
        
        do {
            let response = try await httpClient.request(
                PushResponse.self,
                at: PushAPI.register(clientId: clientIdMutlibase, token: deviceToken, projectId: projectId, environment: environment, auth: pushAuthToken)
            )
            guard response.status == .success else {
                throw Errors.registrationFailed
            }
            logger.debug("Successfully registered at Echo Server")
        } catch {
            if (error as? HTTPError) == .couldNotConnect && !fallback {
                fallback = true
                await echoHostFallback()
                try await register(deviceToken: deviceToken)
            }
            throw error
        }
    }
#endif
}


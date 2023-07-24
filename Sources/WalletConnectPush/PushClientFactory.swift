import Foundation

public struct PushClientFactory {
    public static func create(projectId: String,
                              pushHost: String,
                              environment: APNSEnvironment) -> PushClient {

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")

        return PushClientFactory.create(
            projectId: projectId,
            pushHost: pushHost,
            keychainStorage: keychainStorage,
            environment: environment)
    }

    public static func create(projectId: String,
                       pushHost: String,
                       keychainStorage: KeychainStorageProtocol,
                       environment: APNSEnvironment) -> PushClient {

        let logger = ConsoleLogger(suffix: "👂🏻", loggingLevel: .debug)

        let httpClient = HTTPNetworkClient(host: pushHost)

        let clientIdStorage = ClientIdStorage(keychain: keychainStorage)

        let pushAuthenticator = PushAuthenticator(clientIdStorage: clientIdStorage, pushHost: pushHost)

        let registerService = PushRegisterService(httpClient: httpClient, projectId: projectId, clientIdStorage: clientIdStorage, pushAuthenticator: pushAuthenticator, logger: logger, environment: environment)

        return PushClient(registerService: registerService)
    }
}

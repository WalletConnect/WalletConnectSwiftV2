import Foundation

public struct PushClientFactory {
    public static func create(
        projectId: String,
        pushHost: String,
        groupIdentifier: String,
        environment: APNSEnvironment
    ) -> PushClient {


        guard let keyValueStorage = UserDefaults(suiteName: groupIdentifier) else {
            fatalError("Could not instantiate UserDefaults for a group identifier \(groupIdentifier)")
        }
        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk", accessGroup: groupIdentifier)
        
        return PushClientFactory.create(
            projectId: projectId,
            pushHost: pushHost,
            keyValueStorage: keyValueStorage,
            keychainStorage: keychainStorage,
            environment: environment)
    }

    public static func create(
        projectId: String,
        pushHost: String,
        keyValueStorage: KeyValueStorage,
        keychainStorage: KeychainStorageProtocol,
        environment: APNSEnvironment
    ) -> PushClient {
        let sessionConfiguration = URLSessionConfiguration.default
        sessionConfiguration.timeoutIntervalForRequest = 10.0
        sessionConfiguration.timeoutIntervalForResource = 10.0
        let session = URLSession(configuration: sessionConfiguration)

        let logger = ConsoleLogger(prefix: "👂🏻", loggingLevel: .off)
        let httpClient = HTTPNetworkClient(host: pushHost, session: session)

        let clientIdStorage = ClientIdStorage(defaults: keyValueStorage, keychain: keychainStorage, logger: logger)

        let pushAuthenticator = PushAuthenticator(clientIdStorage: clientIdStorage, pushHost: pushHost)

        let registerService = PushRegisterService(httpClient: httpClient, projectId: projectId, clientIdStorage: clientIdStorage, pushAuthenticator: pushAuthenticator, logger: logger, environment: environment)

        return PushClient(registerService: registerService, logger: logger)
    }
}

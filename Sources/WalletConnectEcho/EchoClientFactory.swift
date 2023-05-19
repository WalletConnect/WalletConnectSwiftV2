import Foundation
import HTTPClient

public struct EchoClientFactory {
    public static func create(projectId: String,
                              clientId: String,
                              echoHost: String,
                              environment: APNSEnvironment) -> EchoClient {

        let httpClient = HTTPNetworkClient(host: echoHost)

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")

        let clientIdStorage = ClientIdStorage(keychain: keychainStorage)

        let echoAuthenticator = EchoAuthenticator(clientIdStorage: clientIdStorage, echoHost: echoHost)

        return EchoClientFactory.create(
            projectId: projectId,
            clientId: clientId,
            httpClient: httpClient,
            echoAuthenticator: echoAuthenticator,
            environment: environment)
    }

    static func create(projectId: String,
                       clientId: String,
                       httpClient: HTTPClient,
                       echoAuthenticator: EchoAuthenticating,
                       environment: APNSEnvironment) -> EchoClient {

        let logger = ConsoleLogger(loggingLevel: .debug)

        let registerService = EchoRegisterService(httpClient: httpClient, projectId: projectId, clientId: clientId, echoAuthenticator: echoAuthenticator, logger: logger, environment: environment)

        return EchoClient(
            registerService: registerService)
    }
}

import Foundation
import WalletConnectNetworking

public struct EchoClientFactory {
    public static func create(projectId: String, clientId: String, echoHost: String, environment: APNSEnvironment) -> EchoClient {

        let httpClient = HTTPNetworkClient(host: echoHost)

        return EchoClientFactory.create(
            projectId: projectId,
            clientId: clientId,
            httpClient: httpClient,
            environment: environment)
    }

    static func create(projectId: String,
                       clientId: String,
                       httpClient: HTTPClient,
                       environment: APNSEnvironment) -> EchoClient {

        let logger = ConsoleLogger(loggingLevel: .debug)
        let registerService = EchoRegisterService(httpClient: httpClient, projectId: projectId, clientId: clientId, logger: logger, environment: environment)

        return EchoClient(
            registerService: registerService)
    }
}

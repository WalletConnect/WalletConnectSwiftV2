import Foundation
import WalletConnectNetworking

public struct EchoClientFactory {
    public static func create(projectId: String, clientId: String) -> EchoClient {

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")

        return EchoClientFactory.create(
            projectId: projectId,
            clientId: clientId,
            keychainStorage: keychainStorage)
    }

    static func create(projectId: String,
                                   clientId: String,
                                   keychainStorage: KeychainStorageProtocol) -> EchoClient {

        let httpClient = HTTPNetworkClient(host: "echo.walletconnect.com")

        let registerService = EchoRegisterService(httpClient: httpClient, projectId: projectId, clientId: clientId)

        let kms = KeyManagementService(keychain: keychainStorage)

        let serializer = Serializer(kms: kms)

        let decryptionService = DecryptionService(serializer: serializer)

        return EchoClient(
            registerService: registerService,
            decryptionService: decryptionService)
    }
}

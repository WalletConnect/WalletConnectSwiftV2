
import Foundation
import WalletConnectNetworking

public struct EchoClientFactory {
    public static func create(tenantId: String, clientId: String) -> EchoClient {

        let keychainStorage = KeychainStorage(serviceIdentifier: "com.walletconnect.sdk")


        return EchoClientFactory.create(
            tenantId: tenantId,
            clientId: clientId,
            keychainStorage: keychainStorage)
    }


    static func create(tenantId: String,
                       clientId: String,
                       keychainStorage: KeychainStorageProtocol) -> EchoClient {

        let httpClient = HTTPNetworkClient(host: "echo.walletconnect.com")

        let registerService = EchoRegisterService(httpClient: httpClient, tenantId: tenantId, clientId: clientId)

        let kms = KeyManagementService(keychain: keychainStorage)

        let serializer = Serializer(kms: kms)

        let decryptionService = DecryptionService(serializer: serializer)

        return EchoClient(
            registerService: registerService,
            decryptionService: decryptionService)
    }
}


import Foundation
import WalletConnectNetworking

public struct EchoClientFactory {
    public static func create(tenantId: String, clientId: String) -> EchoClient {
        let httpClient = HTTPNetworkClient(host: "echo.walletconnect.com")

        let registerService = EchoRegisterService(httpClient: httpClient, tenantId: tenantId, clientId: clientId)
        return EchoClient(registerService: registerService)
    }
}

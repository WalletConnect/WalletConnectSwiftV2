import WalletConnectNetworking
import WalletConnectPairing
import Auth
import Web3Modal

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        
        let metadata = AppMetadata(
            name: "Showcase App",
            description: "Showcase description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )
        
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())
        Auth.configure(crypto: DefaultCryptoProvider())
        Web3Modal.configure(projectId: InputConfig.projectId, metadata: metadata)
    }
}

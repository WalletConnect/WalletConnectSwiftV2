import WalletConnectNetworking
import WalletConnectPairing
import Auth
import WalletConnectModal

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
        WalletConnectModal.configure(projectId: InputConfig.projectId, metadata: metadata)
    }
}

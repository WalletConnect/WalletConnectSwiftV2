import WalletConnectNetworking
import Web3Wallet
import WalletConnectPush

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )
        
        Web3Wallet.configure(metadata: metadata, signerFactory: DefaultSignerFactory())
        Push.configure()
        
    }
    
}

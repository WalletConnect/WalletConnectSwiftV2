import WalletConnectNetworking
import WalletConnectPairing
import Auth

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())
        Pair.configure(
            metadata: AppMetadata(
                name: "Showcase App",
                description: "Showcase description",
                url: "example.wallet",
                icons: ["https://avatars.githubusercontent.com/u/37784886"]
            ))

        Auth.configure(signerFactory: DefaultSignerFactory())
    }
}

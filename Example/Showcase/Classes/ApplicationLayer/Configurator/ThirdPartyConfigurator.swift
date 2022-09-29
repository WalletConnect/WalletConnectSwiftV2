import WalletConnectRelay
import WalletConnectPairing
import Auth

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Relay.configure(projectId: InputConfig.projectId, socketFactory: SocketFactory())

        Auth.configure(
            metadata: AppMetadata(
                name: "Showcase App",
                description: "Showcase description",
                url: "example.wallet",
                icons: ["https://avatars.githubusercontent.com/u/37784886"]
            ),
            account: Account("eip155:1:0xe5EeF1368781911d265fDB6946613dA61915a501")!
        )
    }
}

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

        Auth.configure(
            account: Account("eip155:1:0xe5EeF1368781911d265fDB6946613dA61915a501")!,
            signerFactory: DefaultSignerFactory()
        )
    }
}

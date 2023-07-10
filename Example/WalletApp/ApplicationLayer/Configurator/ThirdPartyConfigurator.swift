import Foundation

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"]
        )
        
    }
}

import WalletConnectNetworking
import Web3Wallet
import Web3Inbox

struct ThirdPartyConfigurator: Configurator {

    func configure() {
        Networking.configure(projectId: InputConfig.projectId, socketFactory: DefaultSocketFactory())

        let metadata = AppMetadata(
            name: "Example Wallet",
            description: "wallet description",
            url: "example.wallet",
            icons: ["https://avatars.githubusercontent.com/u/37784886"],
            verifyUrl: "verify.walletconnect.com"
        )
        
        Web3Wallet.configure(metadata: metadata, crypto: DefaultCryptoProvider(), environment: BuildConfiguration.shared.apnsEnvironment)

        let account = Account(blockchain: Blockchain("eip155:1")!, address: EthKeyStore.shared.address)!

        Web3Inbox.configure(account: account, config: [.chatEnabled: false, .settingsEnabled: false], onSign: Web3InboxSigner.onSing, environment: BuildConfiguration.shared.apnsEnvironment)
    }
    
}

class Web3InboxSigner {
    static func onSing(_ message: String) -> SigningResult {
        let privateKey = EthKeyStore.shared.privateKeyRaw
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        let signature = try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        return .signed(signature)
    }
}


import Foundation
import WalletConnectIdentity
import Web3
import WalletConnectSigner
import WalletConnectSign

enum ImportAccount: Codable {
    case swift
    case kotlin
    case js
    case custom(privateKey: String)
    case web3Modal(account: Account, topic: String)

    static let swiftId = "swift.eth"
    static let kotlinId = "kotlin.eth"
    static let jsId = "js.eth"
    static let web3ModalId = "web3Modal"

    init?(input: String) {
        switch input.lowercased() {
        case ImportAccount.swiftId:
            self = .swift
        case ImportAccount.kotlinId:
            self = .kotlin
        case ImportAccount.jsId:
            self = .js
        default:
            switch true {
            case input.starts(with: ImportAccount.web3ModalId):
                let components = input.components(separatedBy: "-")
                guard components.count == 3, let account = Account(components[1]) else {
                    return nil
                }
                self = .web3Modal(account: account, topic: components[2])

            default:
                if let _ = try? EthereumPrivateKey(hexPrivateKey: "0x" + input, ctx: nil) {
                    self = .custom(privateKey: input)
                } else if let _ = try? EthereumPrivateKey(hexPrivateKey: input, ctx: nil) {
                    self = .custom(privateKey: input.replacingOccurrences(of: "0x", with: ""))
                } else {
                    return nil
                }
            }
        }
    }

    var storageId: String {
        switch self {
        case .swift:
            return ImportAccount.swiftId
        case .kotlin:
            return ImportAccount.kotlinId
        case .js:
            return ImportAccount.jsId
        case .custom(let privateKey):
            return privateKey
        case .web3Modal(let account, let topic):
            return "\(ImportAccount.web3ModalId)-\(account.absoluteString)-\(topic)"
        }
    }

    var account: Account {
        switch self {
        case .swift:
            return Account("eip155:1:0x5F847B18b4a2Dd0F428796E89CaEe71480a2a98e")!
        case .kotlin:
            return Account("eip155:1:0xC313B6F74FcB89147e751220184F0C56D37a210e")!
        case .js:
            return Account("eip155:1:0xd96576825acfDe5182857514C93a204E9aFe3436")!
        case .custom(let privateKey):
            let address = try! EthereumPrivateKey(hexPrivateKey: "0x" + privateKey, ctx: nil).address.hex(eip55: true)
            return Account("eip155:1:\(address)")!
        case .web3Modal(let account, _):
            return account
        }
    }

    var privateKey: String {
        switch self {
        case .swift:
            return "85f52ec43821c1e2e24a248ee464e8d3f883e460acb0506e1eb6b520eb67ae15"
        case .kotlin:
            return "646a0ebac6bd34ba5f498b809148b2aca3793374cafe9dc417cf63bea80450bf"
        case .js:
            return "0e0c9cea8b4854b93e142d1c613d6a6cbd87a506008cd153996275475f20eb7d"
        case .custom(let privateKey):
            return privateKey
        case .web3Modal:
            fatalError("Private key not available")
        }
    }

    func onSign(message: String) -> SigningResult {
        let privateKey = Data(hex: privateKey)
        let signer = MessageSignerFactory(signerFactory: DefaultSignerFactory()).create()
        let signature = try! signer.sign(message: message, privateKey: privateKey, type: .eip191)
        return .signed(signature)
    }

    static func new() -> ImportAccount {
        let key = try! EthereumPrivateKey()
        return ImportAccount.custom(privateKey: key.rawPrivateKey.toHexString())
    }
}

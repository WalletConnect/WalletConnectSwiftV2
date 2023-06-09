import Foundation
import Web3
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
    static let privateKeyId = "privateKey"
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
            case input.starts(with: ImportAccount.privateKeyId):
                if let _ = try? EthereumPrivateKey(hexPrivateKey: "0x" + input, ctx: nil) {
                    self = .custom(privateKey: input)
                } else if let _ = try? EthereumPrivateKey(hexPrivateKey: input, ctx: nil) {
                    self = .custom(privateKey: input.replacingOccurrences(of: "0x", with: ""))
                } else {
                    return nil
                }
            case input.starts(with: ImportAccount.web3ModalId):
                let components = input.components(separatedBy: "-")
                guard components.count == 3, let account = Account(components[1]) else {
                    return nil
                }
                self = .web3Modal(account: account, topic: components[2])
            default:
                return nil
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
            return "\(ImportAccount.privateKeyId)-\(privateKey)"
        case .web3Modal(let account, let topic):
            return "\(ImportAccount.web3ModalId)-\(account.absoluteString)-\(topic)"
        }
    }

    var account: Account {
        switch self {
        case .swift:
            return Account("eip155:1:0x1AAe9864337E821f2F86b5D27468C59AA333C877")!
        case .kotlin:
            return Account("eip155:1:0x4c0fb06CD854ab7D5909E830a5f49D184EB41BF5")!
        case .js:
            return Account("eip155:1:0x7ABa5B1F436e42f6d4A579FB3Ad6D204F6A91863")!
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
            return "4dc0055d1831f7df8d855fc8cd9118f4a85ddc05395104c4cb0831a6752621a8"
        case .kotlin:
            return "ebe738a76b9a3b7457c3d5eca8d3d9ea6909bc563e05b6e0c5c35448f93100a0"
        case .js:
            return "de15cb11963e9bde0a5cce06a5ee2bda1cf3a67be6fbcd7a4fc8c0e4c4db0298"
        case .custom(let privateKey):
            return privateKey
        case .web3Modal:
            fatalError("Private key not available")
        }
    }

    static func new() -> ImportAccount {
        let key = try! EthereumPrivateKey()
        return ImportAccount.custom(privateKey: key.rawPrivateKey.toHexString())
    }
}

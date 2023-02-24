import Foundation
import Web3

enum ImportAccount {
    case swift
    case kotlin
    case js
    case custom(privateKey: String)

    init?(input: String) {
        switch input.lowercased() {
        case ImportAccount.swift.name:
            self = .swift
        case ImportAccount.kotlin.name:
            self = .kotlin
        case ImportAccount.js.name:
            self = .js
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

    var name: String {
        switch self {
        case .swift:
            return "swift.eth"
        case .kotlin:
            return "kotlin.eth"
        case .js:
            return "js.eth"
        case .custom:
            return account.address
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
            let address = try! EthereumPrivateKey(hexPrivateKey: "0x" + privateKey, ctx: nil).address.rawAddress
            return Account("eip155:1:\(address))")!
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
        }
    }
}

import Foundation
import Commons
import Web3

struct ETHSigner {
    private let importAccount: ImportAccount

    init(importAccount: ImportAccount) {
        self.importAccount = importAccount
    }

    var address: String {
        return privateKey.address.hex(eip55: true)
    }

    private var privateKey: EthereumPrivateKey {
        return try! EthereumPrivateKey(hexPrivateKey: importAccount.privateKey)
    }

    func personalSign(_ params: AnyCodable) -> AnyCodable {
        let params = try! params.get([String].self)
        let messageToSign = params[0]

        // Determine if the message is hex-encoded or plain text
        let dataToSign: Bytes
        if messageToSign.hasPrefix("0x") {
            // Hex-encoded message, remove "0x" and convert
            let messageData = Data(hex: String(messageToSign.dropFirst(2)))
            dataToSign = dataToHash(messageData)
        } else {
            // Plain text message, convert directly to data
            let messageData = Data(messageToSign.utf8)
            dataToSign = dataToHash(messageData)
        }

        // Sign the data
        let (v, r, s) = try! privateKey.sign(message: .init(Data(dataToSign)))
        let result = "0x" + r.toHexString() + s.toHexString() + String(v + 27, radix: 16)
        return AnyCodable(result)
    }

    func signTypedData(_ params: AnyCodable) -> AnyCodable {
        let result = "0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b915621c"
        return AnyCodable(result)
    }

    func sendTransaction(_ params: AnyCodable) throws -> AnyCodable {
        let params = try params.get([EthereumTransaction].self)
        var transaction = params[0]
        transaction.gas = EthereumQuantity(quantity: BigUInt("1234"))
        transaction.nonce = EthereumQuantity(quantity: BigUInt("0"))
        transaction.gasPrice = EthereumQuantity(quantity: BigUInt(0))
        print(transaction.description)
        let signedTx = try transaction.sign(with: self.privateKey, chainId: 4)
        let (r, s, v) = (signedTx.r, signedTx.s, signedTx.v)
        let result = r.hex() + s.hex().dropFirst(2) + String(v.quantity, radix: 16)
        return AnyCodable(result)
    }

    private func dataToHash(_ data: Data) -> Bytes {
        let prefix = "\u{19}Ethereum Signed Message:\n"
        let prefixData = (prefix + String(data.count)).data(using: .utf8)!
        let prefixedMessageData = prefixData + data
        return .init(hex: prefixedMessageData.toHexString())
    }
}
